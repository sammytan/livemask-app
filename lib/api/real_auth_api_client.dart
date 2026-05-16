import 'package:dio/dio.dart';
import '../models/auth_models.dart';
import 'auth_api_client.dart';

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

  @override
  Future<RegisterResponse> register(RegisterRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(
      '${baseUrl}api/v1/auth/register',
      data: request.toJson(),
    );
    return RegisterResponse.fromJson(response.data ?? <String, dynamic>{});
  }

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _httpClient.post<Map<String, dynamic>>(
      '${baseUrl}api/v1/auth/login',
      data: request.toJson(),
    );
    return LoginResponse.fromJson(response.data ?? <String, dynamic>{});
  }

  @override
  Future<LoginResponse> refresh(String? refreshToken) async {
    final response = await _httpClient.post<Map<String, dynamic>>(
      '${baseUrl}api/v1/auth/refresh',
      data: {
        'refresh_token': refreshToken ?? '',
        'client_type': 'app',
      },
    );
    return LoginResponse.fromJson(response.data ?? <String, dynamic>{});
  }

  @override
  Future<void> logout() async {
    await _httpClient.post<Map<String, dynamic>>(
      '${baseUrl}api/v1/auth/logout',
    );
  }

  @override
  Future<UserSummary> me() async {
    final response = await _httpClient.get<Map<String, dynamic>>(
      '${baseUrl}api/v1/me',
    );
    return UserSummary.fromJson(response.data ?? <String, dynamic>{});
  }
}
