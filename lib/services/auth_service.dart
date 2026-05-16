import 'package:dio/dio.dart';
import '../api/auth_api_client.dart';
import '../api/auth_token_interceptor.dart';
import '../api/mock_auth_api_client.dart';
import '../api/real_auth_api_client.dart';
import '../models/auth_models.dart';
import '../storage/token_storage.dart';

/// Whether to use the mock API client (true when Backend is not ready).
const bool kUseMockAuthClient = true;

/// Creates a Dio instance with the auth token interceptor configured.
Dio _createAuthenticatedDio({
  required TokenStorage tokenStorage,
  required Future<LoginResponse> Function() onRefresh,
}) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));
  dio.interceptors.add(AuthTokenInterceptor(
    tokenStorage: tokenStorage,
    onRefresh: onRefresh,
  ));
  return dio;
}

/// Core auth service that orchestrates login, logout, refresh, and /me calls.
///
/// Handles the difference between mock and real API clients transparently.
class AuthService {
  AuthService({
    required this.storage,
    AuthApiClient? apiClient,
  }) : _apiClient = apiClient ?? _createDefaultApi(storage);

  final TokenStorage storage;
  final AuthApiClient _apiClient;

  /// Creates the default API client based on [kUseMockAuthClient].
  static AuthApiClient _createDefaultApi(TokenStorage storage) {
    if (kUseMockAuthClient) {
      return MockAuthApiClient();
    }
    final dio = _createAuthenticatedDio(
      tokenStorage: storage,
      onRefresh: () async {
        final refreshToken = await storage.readRefreshToken();
        final refreshDio = Dio(BaseOptions(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ));
        final client = RealAuthApiClient(httpClient: refreshDio);
        return client.refresh(refreshToken);
      },
    );
    return RealAuthApiClient(httpClient: dio);
  }

  // ---- Public API ----

  /// Login with email and password.
  Future<LoginResponse> login({
    required String email,
    required String password,
    String clientType = 'app',
  }) async {
    final request = LoginRequest(
      email: email,
      password: password,
      clientType: clientType,
    );
    final response = await _apiClient.login(request);
    await storage.saveSession(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
      userId: response.user.userId,
    );
    return response;
  }

  /// Register a new account.
  Future<RegisterResponse> register({
    required String email,
    required String password,
    String? displayName,
    String? referralCode,
    required String requestId,
    String clientType = 'app',
  }) async {
    final request = RegisterRequest(
      requestId: requestId,
      email: email,
      password: password,
      displayName: displayName,
      referralCode: referralCode,
      clientType: clientType,
    );
    final response = await _apiClient.register(request);
    if (response.accessToken != null) {
      await storage.saveSession(
        accessToken: response.accessToken!,
        refreshToken: response.refreshToken,
        userId: response.userId,
      );
    }
    return response;
  }

  /// Refresh the access token.
  Future<LoginResponse> refresh() async {
    final refreshToken = await storage.readRefreshToken();
    final response = await _apiClient.refresh(refreshToken);
    await storage.saveSession(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    return response;
  }

  /// Logout: clear local tokens and notify Backend.
  Future<void> logout() async {
    try {
      await _apiClient.logout();
    } catch (_) {
      // Continue even if Backend call fails — local state must be cleared.
    }
    await storage.clearSession();
  }

  /// Fetch current user info from Backend.
  Future<UserSummary> fetchMe() async {
    return _apiClient.me();
  }

  /// Check if a stored session exists.
  Future<bool> hasSession() async {
    return storage.hasSession();
  }

  /// Load user from stored session (returns null if no session or fetch fails).
  Future<UserSummary?> loadCurrentUser() async {
    final hasSession = await storage.hasSession();
    if (!hasSession) return null;
    try {
      return await fetchMe();
    } catch (_) {
      return null;
    }
  }
}
