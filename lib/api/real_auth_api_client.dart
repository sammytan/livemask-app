import 'package:dio/dio.dart';
import '../models/auth_models.dart';
import 'auth_api_client.dart';
import 'mock_auth_api_client.dart';

/// Real API client for auth endpoints using Dio.
///
/// All methods communicate with the Backend according to the auth-rbac.md contract.
class RealAuthApiClient implements AuthApiClient {
  RealAuthApiClient({
    required Dio httpClient,
    this.baseUrl = '',
  }) : _httpClient = httpClient;

  final Dio _httpClient;
  final String baseUrl;

  String _url(String path) {
    if (baseUrl.isEmpty) {
      return '/$path';
    }
    return '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/$path';
  }

  @override
  Future<RegisterResponse> register(RegisterRequest request) async {
    try {
      final response = await _httpClient.post<Map<String, dynamic>>(
        _url('api/v1/auth/register'),
        data: request.toJson(),
      );
      return RegisterResponse.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (e) {
      throw _toStateException(e);
    }
  }

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await _httpClient.post<Map<String, dynamic>>(
        _url('api/v1/auth/login'),
        data: request.toJson(),
      );
      return LoginResponse.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (e) {
      throw _toStateException(e);
    }
  }

  @override
  Future<LoginResponse> refresh(String? refreshToken) async {
    try {
      final response = await _httpClient.post<Map<String, dynamic>>(
        _url('api/v1/auth/refresh'),
        data: {
          'refresh_token': refreshToken ?? '',
          'client_type': 'app',
        },
      );
      return LoginResponse.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (e) {
      throw _toStateException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _httpClient.post<Map<String, dynamic>>(
        _url('api/v1/auth/logout'),
      );
    } on DioException catch (e) {
      throw _toStateException(e);
    }
  }

  @override
  Future<UserSummary> me() async {
    try {
      final response = await _httpClient.get<Map<String, dynamic>>(
        _url('api/v1/me'),
      );
      return UserSummary.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (e) {
      throw _toStateException(e);
    }
  }

  DioStateException _toStateException(DioException e) {
    final statusCode = e.response?.statusCode ?? 0;
    final data = e.response?.data;
    String? errorCode;
    String? message;

    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        errorCode = error['code']?.toString();
        message = error['message']?.toString();
      } else {
        errorCode = data['code']?.toString();
        message = data['message']?.toString();
      }
    }

    return DioStateException(
      statusCode: statusCode,
      errorCode: errorCode ?? _fallbackCode(e),
      message: message ?? _fallbackMessage(e, statusCode),
    );
  }

  String _fallbackCode(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'NETWORK_TIMEOUT';
      case DioExceptionType.connectionError:
        return 'NETWORK_CONNECTION_ERROR';
      case DioExceptionType.badResponse:
        return 'HTTP_${e.response?.statusCode ?? 0}';
      case DioExceptionType.cancel:
        return 'REQUEST_CANCELLED';
      default:
        return 'AUTH_REQUEST_FAILED';
    }
  }

  String _fallbackMessage(DioException e, int statusCode) {
    if (statusCode == 401) {
      return 'Email or password is incorrect.';
    }
    if (statusCode == 403) {
      return 'This account is not allowed to access this client.';
    }
    if (statusCode >= 500) {
      return 'Backend is temporarily unavailable. Please try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to Backend. Check API_BASE_URL and local runtime.';
    }
    return 'Auth request failed. Please try again.';
  }
}
