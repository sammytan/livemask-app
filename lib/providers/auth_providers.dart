import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/auth_api_client.dart';
import '../api/mock_auth_api_client.dart';
import '../api/real_auth_api_client.dart';
import '../config/app_config.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';
import '../services/dio_factory.dart';
import '../storage/token_storage.dart';

// ============================================================
// Low-level dependency providers
// ============================================================

/// FlutterSecureStorage instance.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// TokenStorage — wraps FlutterSecureStorage.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(secureStorage: ref.watch(secureStorageProvider));
});

/// Abstract AuthApiClient provider.
///
/// Returns [MockAuthApiClient] when `AUTH_CLIENT_MODE=mock` (default),
/// or [RealAuthApiClient] when `AUTH_CLIENT_MODE=real`.
final authApiClientProvider = Provider<AuthApiClient>((ref) {
  if (AppConfig.useMockAuthClient) {
    return MockAuthApiClient();
  }
  final storage = ref.watch(tokenStorageProvider);
  final dio = _createAuthenticatedDio(storage);
  return RealAuthApiClient(
    httpClient: dio,
    baseUrl: AppConfig.apiBaseUrl,
  );
});

/// Creates a Dio instance with the auth interceptor for the real client.
Dio _createAuthenticatedDio(TokenStorage storage) {
  return DioFactory.createAuthenticatedDio(
    tokenStorage: storage,
    onRefresh: () async {
      final refreshToken = await storage.readRefreshToken();
      final client = RealAuthApiClient(
        httpClient: DioFactory.createPlainDio(),
        baseUrl: AppConfig.apiBaseUrl,
      );
      return client.refresh(refreshToken);
    },
  );
}

/// AuthService provider.
final authServiceProvider = Provider<AuthService>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final apiClient = ref.watch(authApiClientProvider);
  return AuthService(storage: storage, apiClient: apiClient);
});

// ============================================================
// Shared authenticated Dio for future API calls (config, nodes, etc.)
// ============================================================

/// A Dio instance with Bearer token injection and refresh-on-401.
///
/// Used by [ConfigApiClient], future recommendation API, feedback API, etc.
/// Falls back to a plain Dio when `AUTH_CLIENT_MODE=mock`.
final authenticatedDioProvider = Provider<Dio>((ref) {
  if (AppConfig.useMockAuthClient) {
    return DioFactory.createPlainDio();
  }
  final storage = ref.watch(tokenStorageProvider);
  return _createAuthenticatedDio(storage);
});

// ============================================================
// Auth state management
// ============================================================

/// StateNotifier that manages [AuthNotifierState] transitions.
final authStateProvider =
    StateNotifierProvider<AuthNotifier, AuthNotifierState>((ref) {
  return AuthNotifier(ref);
});

class AuthNotifier extends StateNotifier<AuthNotifierState> {
  AuthNotifier(this._ref) : super(AuthNotifierState.initial);

  final Ref _ref;

  AuthService get _authService => _ref.read(authServiceProvider);

  /// Check stored session on app startup.
  Future<void> tryRestoreSession() async {
    state = state.copyWith(status: AuthState.loading);
    try {
      final hasSession = await _authService.hasSession();
      if (!hasSession) {
        state = AuthNotifierState(status: AuthState.unauthenticated);
        return;
      }

      // Try fetching user info.
      try {
        final user = await _authService.fetchMe();
        state = AuthNotifierState(
          status: AuthState.authenticated,
          user: user,
        );
        return;
      } catch (_) {
        // Access token might be expired — try refresh.
      }

      try {
        final refreshResult = await _authService.refresh();
        final user = refreshResult.user;
        state = AuthNotifierState(
          status: AuthState.authenticated,
          user: user,
        );
      } catch (_) {
        await _authService.logout();
        state = AuthNotifierState(status: AuthState.unauthenticated);
      }
    } catch (_) {
      state = AuthNotifierState(status: AuthState.unauthenticated);
    }
  }

  /// Login with email and password.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthState.loading, clearError: true);
    try {
      final response = await _authService.login(
        email: email,
        password: password,
        clientType: 'app',
      );
      state = AuthNotifierState(
        status: AuthState.authenticated,
        user: response.user,
      );
    } on DioStateException catch (e) {
      state = AuthNotifierState(
        status: AuthState.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = AuthNotifierState(
        status: AuthState.error,
        errorMessage: 'An unexpected error occurred.',
      );
    }
  }

  /// Register a new account.
  Future<void> register({
    required String email,
    required String password,
    String? displayName,
    String? referralCode,
    required String requestId,
  }) async {
    state = state.copyWith(status: AuthState.loading, clearError: true);
    try {
      final response = await _authService.register(
        email: email,
        password: password,
        displayName: displayName,
        referralCode: referralCode,
        requestId: requestId,
        clientType: 'app',
      );
      if (response.accessToken != null) {
        state = AuthNotifierState(
          status: AuthState.authenticated,
          user: UserSummary(
            userId: response.userId,
            email: email,
            roles: ['user'],
            permissions: [],
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      } else {
        state = AuthNotifierState(status: AuthState.unauthenticated);
      }
    } on DioStateException catch (e) {
      state = AuthNotifierState(
        status: AuthState.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = AuthNotifierState(
        status: AuthState.error,
        errorMessage: 'An unexpected error occurred.',
      );
    }
  }

  /// Logout.
  Future<void> logout() async {
    state = state.copyWith(status: AuthState.loading);
    try {
      await _authService.logout();
    } catch (_) {}
    state = state.copyWith(status: AuthState.unauthenticated, clearUser: true);
  }
}
