import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:livemask_app/models/auth_models.dart';
import 'package:livemask_app/services/auth_service.dart';
import 'package:livemask_app/storage/token_storage.dart';

class MockTokenStorage extends FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> write({required String key, required String? value}) async {
    if (value != null) _store[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _store[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _store.remove(key);
  }

  @override
  Future<bool> containsKey({required String key}) async {
    return _store.containsKey(key);
  }
}

void main() {
  group('AuthService', () {
    late TokenStorage storage;
    late AuthService service;

    setUp(() {
      storage = TokenStorage(secureStorage: MockTokenStorage());
      service = AuthService(storage: storage); // uses MockAuthApiClient by default
    });

    test('login succeeds with valid credentials', () async {
      final response = await service.login(
        email: 'test@livemask.app',
        password: 'password123',
      );

      expect(response.accessToken, isNotEmpty);
      expect(response.user.email, 'test@livemask.app');

      // Verify tokens are persisted.
      expect(await storage.hasSession(), true);
      expect(await storage.readUserId(), isNotNull);
    });

    test('login throws with invalid credentials', () async {
      expect(
        () => service.login(
          email: 'test@livemask.app',
          password: 'wrong',
        ),
        throwsException,
      );
    });

    test('hasSession returns false after logout', () async {
      await service.login(
        email: 'test@livemask.app',
        password: 'password123',
      );
      expect(await storage.hasSession(), true);

      await service.logout();
      expect(await storage.hasSession(), false);
    });

    test('refresh returns new tokens', () async {
      // Login first to set refresh token.
      await service.login(
        email: 'test@livemask.app',
        password: 'password123',
      );

      final refreshResult = await service.refresh();
      expect(refreshResult.accessToken, contains('refreshed'));
    });

    test('register creates account and persists tokens', () async {
      final response = await service.register(
        email: 'new-user@test.com',
        password: 'password123',
        requestId: 'test-reg-1',
      );

      expect(response.userId, isNotEmpty);
      expect(response.accessToken, isNotNull);
      expect(await storage.hasSession(), true);
    });

    test('loadCurrentUser returns user when logged in', () async {
      await service.login(
        email: 'test@livemask.app',
        password: 'password123',
      );

      final user = await service.loadCurrentUser();
      expect(user, isNotNull);
      expect(user!.email, 'test@livemask.app');
    });

    test('loadCurrentUser returns null when no session', () async {
      final user = await service.loadCurrentUser();
      expect(user, isNull);
    });
  });
}
