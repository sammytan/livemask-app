import 'package:flutter_test/flutter_test.dart';
import 'package:livemask_app/api/mock_auth_api_client.dart';
import 'package:livemask_app/models/auth_models.dart';

void main() {
  group('MockAuthApiClient', () {
    late MockAuthApiClient client;

    setUp(() {
      client = MockAuthApiClient();
    });

    group('login', () {
      test('succeeds with valid credentials', () async {
        final response = await client.login(LoginRequest(
          email: 'test@livemask.app',
          password: 'password123',
          clientType: 'app',
        ));

        expect(response.accessToken, contains('mock-access-token'));
        expect(response.refreshToken, contains('mock-refresh-token'));
        expect(response.expiresIn, 900);
        expect(response.user.email, 'test@livemask.app');
        expect(response.user.roles, contains('user'));
      });

      test('fails with wrong password', () async {
        expect(
          () => client.login(LoginRequest(
            email: 'test@livemask.app',
            password: 'wrong',
            clientType: 'app',
          )),
          throwsA(isA<DioStateException>()),
        );
      });

      test('fails with wrong email', () async {
        expect(
          () => client.login(LoginRequest(
            email: 'unknown@test.com',
            password: 'password123',
            clientType: 'app',
          )),
          throwsA(isA<DioStateException>()),
        );
      });
    });

    group('register', () {
      test('succeeds with new email', () async {
        final response = await client.register(RegisterRequest(
          requestId: 'req-1',
          email: 'new@test.com',
          password: 'password123',
          clientType: 'app',
        ));

        expect(response.userId, contains('mock-user-id'));
        expect(response.emailVerificationRequired, true);
        expect(response.accessToken, isNotNull);
        expect(response.refreshToken, isNotNull);
      });

      test('fails with duplicate email', () async {
        expect(
          () => client.register(RegisterRequest(
            requestId: 'req-2',
            email: 'already@used.com',
            password: 'password123',
            clientType: 'app',
          )),
          throwsA(isA<DioStateException>()),
        );
      });
    });

    group('refresh', () {
      test('succeeds with valid refresh token', () async {
        final response = await client.refresh('valid-refresh-token');

        expect(response.accessToken, contains('refreshed'));
        expect(response.refreshToken, contains('refreshed'));
        expect(response.user.email, 'test@livemask.app');
      });

      test('fails with null refresh token', () async {
        expect(
          () => client.refresh(null),
          throwsA(isA<DioStateException>()),
        );
      });

      test('fails with empty refresh token', () async {
        expect(
          () => client.refresh(''),
          throwsA(isA<DioStateException>()),
        );
      });
    });

    group('me', () {
      test('returns user after successful login', () async {
        await client.login(LoginRequest(
          email: 'test@livemask.app',
          password: 'password123',
          clientType: 'app',
        ));

        final user = await client.me();
        expect(user.userId, 'mock-user-001');
        expect(user.email, 'test@livemask.app');
        expect(user.roles, ['user']);
        expect(user.permissions, contains('config:read'));
        expect(user.subscriptionStatus, 'active');
      });

      test('throws without prior login', () async {
        expect(
          () => client.me(),
          throwsA(isA<DioStateException>()),
        );
      });
    });

    group('logout', () {
      test('clears session state', () async {
        await client.login(LoginRequest(
          email: 'test@livemask.app',
          password: 'password123',
          clientType: 'app',
        ));

        await client.logout();

        expect(
          () => client.me(),
          throwsA(isA<DioStateException>()),
        );
      });
    });
  });
}
