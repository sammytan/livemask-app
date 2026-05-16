import 'package:flutter_test/flutter_test.dart';
import 'package:livemask_app/models/auth_models.dart';

void main() {
  group('UserSummary', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'user_id': 'uuid-123',
        'email': 'test@livemask.app',
        'display_name': 'Test User',
        'roles': ['user', 'subscriber'],
        'permissions': ['config:read'],
        'subscription_status': 'active',
        'created_at': '2026-05-01T00:00:00Z',
      };

      final user = UserSummary.fromJson(json);

      expect(user.userId, 'uuid-123');
      expect(user.email, 'test@livemask.app');
      expect(user.displayName, 'Test User');
      expect(user.roles, ['user', 'subscriber']);
      expect(user.permissions, ['config:read']);
      expect(user.subscriptionStatus, 'active');
      expect(user.createdAt, '2026-05-01T00:00:00Z');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'user_id': 'uuid-123',
        'email': 'test@livemask.app',
        'roles': [],
        'permissions': [],
        'created_at': '2026-05-01T00:00:00Z',
      };

      final user = UserSummary.fromJson(json);

      expect(user.displayName, isNull);
      expect(user.subscriptionStatus, isNull);
    });

    test('toJson produces round-trip output', () {
      final original = UserSummary(
        userId: 'uuid-123',
        email: 'test@livemask.app',
        displayName: 'Test',
        roles: ['user'],
        permissions: ['config:read'],
        subscriptionStatus: 'active',
        createdAt: '2026-05-01T00:00:00Z',
      );

      final json = original.toJson();
      final restored = UserSummary.fromJson(json);

      expect(restored.userId, original.userId);
      expect(restored.email, original.email);
      expect(restored.displayName, original.displayName);
      expect(restored.roles, original.roles);
      expect(restored.permissions, original.permissions);
      expect(restored.subscriptionStatus, original.subscriptionStatus);
    });

    test('isAdmin returns true for admin roles', () {
      final admin = UserSummary(
        userId: '1',
        email: 'admin@test.com',
        roles: ['admin'],
        permissions: [],
        createdAt: '',
      );
      expect(admin.isAdmin, true);
    });

    test('isAdmin returns false for user role', () {
      final user = UserSummary(
        userId: '1',
        email: 'user@test.com',
        roles: ['user'],
        permissions: [],
        createdAt: '',
      );
      expect(user.isAdmin, false);
    });
  });

  group('TokenPair', () {
    test('fromJson parses all fields', () {
      final json = {
        'access_token': 'at-123',
        'refresh_token': 'rt-456',
        'expires_in': 900,
      };

      final pair = TokenPair.fromJson(json);

      expect(pair.accessToken, 'at-123');
      expect(pair.refreshToken, 'rt-456');
      expect(pair.expiresIn, 900);
      expect(pair.hasValidAccessToken, true);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'access_token': 'at-123',
      };

      final pair = TokenPair.fromJson(json);

      expect(pair.accessToken, 'at-123');
      expect(pair.refreshToken, isNull);
      expect(pair.expiresIn, isNull);
    });

    test('hasValidAccessToken is false for empty token', () {
      final pair = TokenPair(accessToken: '');
      expect(pair.hasValidAccessToken, false);
    });
  });

  group('LoginResponse', () {
    test('fromJson parses full response', () {
      final json = {
        'user': {
          'user_id': 'uuid-1',
          'email': 'test@test.com',
          'roles': ['user'],
          'permissions': [],
          'created_at': '2026-01-01T00:00:00Z',
        },
        'access_token': 'at-1',
        'refresh_token': 'rt-1',
        'expires_in': 900,
      };

      final response = LoginResponse.fromJson(json);

      expect(response.user.userId, 'uuid-1');
      expect(response.accessToken, 'at-1');
      expect(response.refreshToken, 'rt-1');
      expect(response.expiresIn, 900);
    });
  });

  group('RegisterRequest', () {
    test('toJson produces correct fields', () {
      final request = RegisterRequest(
        requestId: 'req-1',
        email: 'new@test.com',
        password: 'secure123',
        displayName: 'New User',
        referralCode: 'REF123',
        clientType: 'app',
      );

      final json = request.toJson();

      expect(json['request_id'], 'req-1');
      expect(json['email'], 'new@test.com');
      expect(json['password'], 'secure123');
      expect(json['display_name'], 'New User');
      expect(json['referral_code'], 'REF123');
      expect(json['client_type'], 'app');
    });
  });

  group('LoginRequest', () {
    test('toJson produces correct fields', () {
      final request = LoginRequest(
        email: 'test@test.com',
        password: 'pass',
        clientType: 'web',
      );

      final json = request.toJson();

      expect(json['email'], 'test@test.com');
      expect(json['password'], 'pass');
      expect(json['client_type'], 'web');
    });
  });

  group('AuthNotifierState', () {
    test('initial state is unauthenticated', () {
      final state = AuthNotifierState.initial;
      expect(state.status, AuthState.unauthenticated);
      expect(state.isAuthenticated, false);
      expect(state.isLoading, false);
    });

    test('copyWith updates fields', () {
      final state = AuthNotifierState.initial;
      final updated = state.copyWith(
        status: AuthState.loading,
      );

      expect(updated.isLoading, true);
    });

    test('copyWith clearUser removes user', () {
      final state = AuthNotifierState(
        status: AuthState.authenticated,
        user: UserSummary(
          userId: '1',
          email: 't@t.com',
          roles: [],
          permissions: [],
          createdAt: '',
        ),
      );

      final cleared = state.copyWith(clearUser: true, status: AuthState.unauthenticated);
      expect(cleared.user, isNull);
    });

    test('copyWith clearError removes error message', () {
      final state = AuthNotifierState(
        status: AuthState.error,
        errorMessage: 'some error',
      );

      final cleared = state.copyWith(status: AuthState.loading, clearError: true);
      expect(cleared.errorMessage, isNull);
    });
  });
}
