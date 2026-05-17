import 'package:dio/dio.dart';
import '../api/auth_token_interceptor.dart';
import '../config/app_config.dart';
import '../models/auth_models.dart';
import '../storage/token_storage.dart';

/// Shared factory for creating [Dio] instances with standard timeouts,
/// content-type headers, and optionally the [AuthTokenInterceptor].
class DioFactory {
  DioFactory._();

  /// Creates a plain [Dio] with default options (no auth interceptor).
  static Dio createPlainDio() {
    return Dio(BaseOptions(
      connectTimeout: Duration(seconds: AppConfig.connectTimeoutSeconds),
      receiveTimeout: Duration(seconds: AppConfig.receiveTimeoutSeconds),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
  }

  /// Creates a [Dio] pre-configured with the [AuthTokenInterceptor].
  static Dio createAuthenticatedDio({
    required TokenStorage tokenStorage,
    required Future<LoginResponse> Function() onRefresh,
  }) {
    final dio = createPlainDio();
    dio.interceptors.add(AuthTokenInterceptor(
      tokenStorage: tokenStorage,
      onRefresh: onRefresh,
      retryClient: dio,
    ));
    return dio;
  }
}
