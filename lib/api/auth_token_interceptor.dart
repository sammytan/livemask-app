import 'package:dio/dio.dart';
import '../models/auth_models.dart';
import '../storage/token_storage.dart';

/// Dio interceptor that:
/// 1. Injects Bearer access token into authenticated requests.
/// 2. On 401, attempts a single token refresh via [onRefresh].
/// 3. On refresh success, retries the original request with the new token.
/// 4. On refresh failure, clears tokens and propagates the 401.
///
/// Safety: a flag prevents infinite refresh retry loops.
class AuthTokenInterceptor extends Interceptor {
  AuthTokenInterceptor({
    required TokenStorage tokenStorage,
    required Future<LoginResponse> Function() onRefresh,
    Dio? retryClient,
  })  : _tokenStorage = tokenStorage,
        _onRefresh = onRefresh,
        _retryClient = retryClient;

  final TokenStorage _tokenStorage;
  final Future<LoginResponse> Function() _onRefresh;
  final Dio? _retryClient;
  bool _isRefreshing = false;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isAuthEndpoint(options.path)) {
      return handler.next(options);
    }

    final token = await _tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only handle 401 errors.
    if (err.response?.statusCode != 401) {
      return handler.next(err);
    }

    // Prevent recursive refresh loops.
    if (_isRefreshing) {
      return handler.next(err);
    }

    // Don't refresh on auth endpoints themselves.
    if (_isAuthEndpoint(err.requestOptions.path)) {
      return handler.next(err);
    }

    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return handler.next(err);
    }

    _isRefreshing = true;
    try {
      final refreshResult = await _onRefresh();

      // Save new tokens.
      await _tokenStorage.saveAccessToken(refreshResult.accessToken);
      if (refreshResult.refreshToken != null) {
        await _tokenStorage.saveRefreshToken(refreshResult.refreshToken!);
      }

      // Retry the original request with the new token.
      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] =
          'Bearer ${refreshResult.accessToken}';
      final dio = _retryClient ?? Dio();
      final retryResponse = await dio.fetch<void>(retryOptions);

      _isRefreshing = false;
      return handler.resolve(retryResponse);
    } catch (_) {
      // Refresh failed — clear session.
      await _tokenStorage.clearSession();
      _isRefreshing = false;
      return handler.next(err);
    }
  }

  bool _isAuthEndpoint(String path) {
    final lower = path.toLowerCase();
    return lower.contains('/auth/login') ||
        lower.contains('/auth/register') ||
        lower.contains('/auth/refresh');
  }
}
