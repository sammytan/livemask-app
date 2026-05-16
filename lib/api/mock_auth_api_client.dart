import '../models/auth_models.dart';
import 'auth_api_client.dart';

/// Mock [AuthApiClient] used when the Backend is not ready.
///
/// Simulates a complete auth flow for development and testing.
/// Accepts "test@livemask.app" / "password123" for login.
class MockAuthApiClient implements AuthApiClient {
  MockAuthApiClient();

  bool _isLoggedIn = false;

  @override
  Future<RegisterResponse> register(RegisterRequest request) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (request.email == 'already@used.com') {
      throw DioStateException(
        statusCode: 409,
        errorCode: 'AUTH_DUPLICATE_EMAIL',
        message: 'An account with this email already exists',
      );
    }
    _isLoggedIn = true;
    return RegisterResponse(
      userId: 'mock-user-id-${DateTime.now().millisecondsSinceEpoch}',
      emailVerificationRequired: true,
      accessToken: 'mock-access-token-reg',
      refreshToken: 'mock-refresh-token-reg',
      expiresIn: 900,
    );
  }

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (request.email == 'test@livemask.app' &&
        request.password == 'password123') {
      _isLoggedIn = true;
      return LoginResponse(
        user: _mockUser(),
        accessToken:
            'mock-access-token-${DateTime.now().millisecondsSinceEpoch}',
        refreshToken:
            'mock-refresh-token-${DateTime.now().millisecondsSinceEpoch}',
        expiresIn: 900,
      );
    }
    throw DioStateException(
      statusCode: 401,
      errorCode: 'AUTH_INVALID_CREDENTIALS',
      message: 'Email or password is incorrect.',
    );
  }

  @override
  Future<LoginResponse> refresh(String? refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (refreshToken == null || refreshToken.isEmpty) {
      throw DioStateException(
        statusCode: 401,
        errorCode: 'AUTH_REFRESH_REVOKED',
        message: 'Session expired. Please log in again.',
      );
    }
    _isLoggedIn = true;
    return LoginResponse(
      user: _mockUser(),
      accessToken:
          'mock-access-token-refreshed-${DateTime.now().millisecondsSinceEpoch}',
      refreshToken:
          'mock-refresh-token-refreshed-${DateTime.now().millisecondsSinceEpoch}',
      expiresIn: 900,
    );
  }

  @override
  Future<void> logout() async {
    _isLoggedIn = false;
  }

  @override
  Future<UserSummary> me() async {
    if (!_isLoggedIn) {
      throw DioStateException(
        statusCode: 401,
        errorCode: 'AUTH_TOKEN_EXPIRED',
        message: 'Authentication required',
      );
    }
    return _mockUser();
  }

  UserSummary _mockUser() {
    return UserSummary(
      userId: 'mock-user-001',
      email: 'test@livemask.app',
      displayName: 'Test User',
      roles: ['user'],
      permissions: [
        'config:read',
        'user:read',
      ],
      subscriptionStatus: 'active',
      createdAt: '2026-05-01T00:00:00Z',
    );
  }
}

/// A structured exception matching the Backend error contract.
class DioStateException implements Exception {
  const DioStateException({
    required this.statusCode,
    required this.errorCode,
    required this.message,
  });

  final int statusCode;
  final String errorCode;
  final String message;

  @override
  String toString() => 'DioStateException($statusCode, $errorCode): $message';
}
