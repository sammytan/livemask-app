import '../models/auth_models.dart';

/// Abstract interface for auth API operations.
///
/// Allows transparent switching between [RealAuthApiClient] and
/// [MockAuthApiClient] depending on Backend readiness.
abstract class AuthApiClient {
  /// POST /api/v1/auth/register
  Future<RegisterResponse> register(RegisterRequest request);

  /// POST /api/v1/auth/login
  Future<LoginResponse> login(LoginRequest request);

  /// POST /api/v1/auth/refresh
  Future<LoginResponse> refresh(String? refreshToken);

  /// POST /api/v1/auth/logout
  Future<void> logout();

  /// GET /api/v1/me
  Future<UserSummary> me();
}
