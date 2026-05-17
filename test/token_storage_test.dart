import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:livemask_app/storage/token_storage.dart';

class MockFlutterSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _store[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }
}

void main() {
  group('TokenStorage', () {
    late MockFlutterSecureStorage mockStorage;
    late TokenStorage storage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      storage = TokenStorage(secureStorage: mockStorage);
    });

    test('save and read access token', () async {
      await storage.saveAccessToken('token-123');
      final result = await storage.readAccessToken();
      expect(result, 'token-123');
    });

    test('save and read refresh token', () async {
      await storage.saveRefreshToken('refresh-abc');
      final result = await storage.readRefreshToken();
      expect(result, 'refresh-abc');
    });

    test('save and read user ID', () async {
      await storage.saveUserId('user-001');
      final result = await storage.readUserId();
      expect(result, 'user-001');
    });

    test('delete access token', () async {
      await storage.saveAccessToken('token-123');
      await storage.deleteAccessToken();
      final result = await storage.readAccessToken();
      expect(result, isNull);
    });

    test('delete refresh token', () async {
      await storage.saveRefreshToken('refresh-abc');
      await storage.deleteRefreshToken();
      final result = await storage.readRefreshToken();
      expect(result, isNull);
    });

    test('saveSession persists all tokens', () async {
      await storage.saveSession(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        userId: 'user-1',
      );

      expect(await storage.readAccessToken(), 'access-1');
      expect(await storage.readRefreshToken(), 'refresh-1');
      expect(await storage.readUserId(), 'user-1');
    });

    test('saveSession with null refresh token', () async {
      await storage.saveSession(
        accessToken: 'access-1',
        userId: 'user-1',
      );

      expect(await storage.readAccessToken(), 'access-1');
      expect(await storage.readRefreshToken(), isNull);
    });

    test('clearSession removes all tokens', () async {
      await storage.saveSession(
        accessToken: 'access-1',
        refreshToken: 'refresh-1',
        userId: 'user-1',
      );
      await storage.clearSession();

      expect(await storage.readAccessToken(), isNull);
      expect(await storage.readRefreshToken(), isNull);
      expect(await storage.readUserId(), isNull);
    });

    test('hasSession returns true when access token exists', () async {
      expect(await storage.hasSession(), false);

      await storage.saveAccessToken('token-123');
      expect(await storage.hasSession(), true);
    });

    test('hasSession returns false after clearSession', () async {
      await storage.saveAccessToken('token-123');
      await storage.clearSession();
      expect(await storage.hasSession(), false);
    });
  });
}
