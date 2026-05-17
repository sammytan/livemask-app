import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livemask_app/api/auth_token_interceptor.dart';
import 'package:livemask_app/models/auth_models.dart';
import 'package:livemask_app/storage/token_storage.dart';

class MockSecureStorage extends FlutterSecureStorage {
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
    if (value != null) _store[key] = value;
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

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store.containsKey(key);
  }
}

class MockAdapter implements HttpClientAdapter {
  int statusCode = 200;
  int requestCount = 0;
  Map<String, dynamic>? lastHeaders;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requestCount++;
    lastHeaders = Map<String, dynamic>.from(options.headers);
    return ResponseBody.fromString(
      jsonEncode(<String, dynamic>{'ok': statusCode < 400}),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

LoginResponse refreshResponse({
  String accessToken = 'new-access-token',
  String? refreshToken = 'new-refresh-token',
}) {
  return LoginResponse(
    user: UserSummary(
      userId: 'user-1',
      email: 'test@livemask.app',
      roles: const [],
      permissions: const [],
      createdAt: '2026-05-17T00:00:00Z',
    ),
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresIn: 900,
  );
}

void main() {
  group('AuthTokenInterceptor', () {
    late TokenStorage tokenStorage;
    late MockSecureStorage mockStorage;
    late MockAdapter adapter;
    late Dio dio;
    int refreshCallCount = 0;

    setUp(() {
      mockStorage = MockSecureStorage();
      tokenStorage = TokenStorage(secureStorage: mockStorage);
      adapter = MockAdapter();
      dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter;
      refreshCallCount = 0;
    });

    void installInterceptor(
      Future<LoginResponse> Function() onRefresh,
    ) {
      dio.interceptors.add(AuthTokenInterceptor(
        tokenStorage: tokenStorage,
        onRefresh: onRefresh,
        retryClient: dio,
      ));
    }

    test('injects Bearer token when available', () async {
      await tokenStorage.saveAccessToken('test-access-token');
      installInterceptor(() async => refreshResponse());

      await dio.get('/api/v1/me');

      expect(adapter.lastHeaders?['Authorization'], 'Bearer test-access-token');
    });

    test('does not inject token for auth endpoints', () async {
      await tokenStorage.saveAccessToken('test-token');
      installInterceptor(() async => refreshResponse());

      await dio.post('/api/v1/auth/login');

      expect(adapter.lastHeaders?.containsKey('Authorization'), false);
    });

    test('does not inject token when no token stored', () async {
      installInterceptor(() async => refreshResponse());

      await dio.get('/api/v1/me');

      expect(adapter.lastHeaders?.containsKey('Authorization'), false);
    });

    test('passes non-401 errors through', () async {
      adapter.statusCode = 500;
      installInterceptor(() async {
        refreshCallCount++;
        return refreshResponse();
      });

      await expectLater(
        dio.get('/api/v1/me'),
        throwsA(isA<DioException>()),
      );
      expect(refreshCallCount, 0);
    });

    test('does not refresh on auth endpoints', () async {
      adapter.statusCode = 401;
      await tokenStorage.saveRefreshToken('rt-1');
      installInterceptor(() async {
        refreshCallCount++;
        return refreshResponse();
      });

      await expectLater(
        dio.post('/api/v1/auth/login'),
        throwsA(isA<DioException>()),
      );
      expect(refreshCallCount, 0);
    });

    test('clears session on failed refresh', () async {
      adapter.statusCode = 401;
      await tokenStorage.saveSession(
        accessToken: 'old-at',
        refreshToken: 'old-rt',
      );
      installInterceptor(() async {
        refreshCallCount++;
        throw Exception('refresh failed');
      });

      await expectLater(
        dio.get('/api/v1/me'),
        throwsA(isA<DioException>()),
      );

      expect(refreshCallCount, 1);
      expect(await tokenStorage.readAccessToken(), isNull);
      expect(await tokenStorage.readRefreshToken(), isNull);
    });

    test('skips refresh when no refresh token is stored', () async {
      adapter.statusCode = 401;
      installInterceptor(() async {
        refreshCallCount++;
        return refreshResponse();
      });

      await expectLater(
        dio.get('/api/v1/me'),
        throwsA(isA<DioException>()),
      );

      expect(refreshCallCount, 0);
    });
  });
}
