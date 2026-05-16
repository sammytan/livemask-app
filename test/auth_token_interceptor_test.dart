import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livemask_app/api/auth_token_interceptor.dart';
import 'package:livemask_app/models/auth_models.dart';
import 'package:livemask_app/storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MockSecureStorage extends FlutterSecureStorage {
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

/// Creates a DioException for test purposes with the given status code.
DioException _mockDioException({
  required String path,
  int? statusCode,
  DioExceptionType type = DioExceptionType.badResponse,
}) {
  return DioException(
    requestOptions: RequestOptions(path: path),
    type: type,
    response: statusCode != null
        ? Response(
            requestOptions: RequestOptions(path: path),
            statusCode: statusCode,
            data: <String, dynamic>{'error': 'mock'},
          )
        : null,
  );
}

void main() {
  group('AuthTokenInterceptor', () {
    late TokenStorage tokenStorage;
    late MockSecureStorage mockStorage;
    int refreshCallCount;

    setUp(() {
      mockStorage = MockSecureStorage();
      tokenStorage = TokenStorage(secureStorage: mockStorage);
      refreshCallCount = 0;
    });

    test('injects Bearer token when available', () async {
      await tokenStorage.saveAccessToken('test-access-token');

      final interceptor = AuthTokenInterceptor(
        tokenStorage: tokenStorage,
        onRefresh: () async => LoginResponse(
          user: UserSummary(
            userId: '',
            email: '',
            roles: [],
            permissions: [],
            createdAt: '',
          ),
          accessToken: '',
          expiresIn: 0,
        ),
      );

      final options = RequestOptions(path: '/api/v1/me');
      await interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.headers['Authorization'], 'Bearer test-access-token');
    });

    test('does not inject token for auth endpoints', () async {
      await tokenStorage.saveAccessToken('test-token');

      final interceptor = AuthTokenInterceptor(
        tokenStorage: tokenStorage,
        onRefresh: () async => LoginResponse(
          user: UserSummary(
            userId: '',
            email: '',
            roles: [],
            permissions: [],
            createdAt: '',
          ),
          accessToken: '',
          expiresIn: 0,
        ),
      );

      final options = RequestOptions(path: '/api/v1/auth/login');
      await interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.headers.containsKey('Authorization'), false);
    });

    test('does not inject token when no token stored', () async {
      final interceptor = AuthTokenInterceptor(
        tokenStorage: tokenStorage,
        onRefresh: () async => LoginResponse(
          user: UserSummary(
            userId: '',
            email: '',
            roles: [],
            permissions: [],
            createdAt: '',
          ),
          accessToken: '',
          expiresIn: 0,
        ),
      );

      final options = RequestOptions(path: '/api/v1/me');
      await interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.headers.containsKey('Authorization'), false);
    });

    test('onError - passes non-401 errors through', () async {
      final interceptor = AuthTokenInterceptor(
        tokenStorage: tokenStorage,
        onRefresh: () async => LoginResponse(
          user: UserSummary(
            userId: '',
            email: '',
            roles: [],
            permissions: [],
            createdAt: '',
          ),
          accessToken: '',
          expiresIn: 0,
        ),
      );

      final err = _mockDioException(
        path: '/api/v1/me',
        statusCode: 500,
      );

      Object? passedError;
      final handler = ErrorInterceptorHandler()
        ..next = (e) {
          passedError = e;
        };

      await interceptor.onError(err, handler);
      expect(passedError, isNotNull);
    });

    test('onError - does not refresh on auth endpoints', () async {
      await tokenStorage.saveRefreshToken('rt-1');

      final interceptor = AuthTokenInterceptor(
        tokenStorage: tokenStorage,
        onRefresh: () async {
          refreshCallCount++;
          return LoginResponse(
            user: UserSummary(
              userId: '',
              email: '',
              roles: [],
              permissions: [],
              createdAt: '',
            ),
            accessToken: 'new',
            refreshToken: 'new-rt',
            expiresIn: 0,
          );
        },
      );

      final err = _mockDioException(
        path: '/api/v1/auth/login',
        statusCode: 401,
      );

      Object? passedError;
      final handler = ErrorInterceptorHandler()
        ..next = (e) {
          passedError = e;
        };

      await interceptor.onError(err, handler);
      expect(refreshCallCount, 0);
      expect(passedError, isNotNull);
    });

    test('onError - clears session on failed refresh', () async {
      await tokenStorage.saveSession(
        accessToken: 'old-at',
        refreshToken: 'old-rt',
      );

      final interceptor = AuthTokenInterceptor(
        tokenStorage: tokenStorage,
        onRefresh: () async {
          refreshCallCount++;
          throw Exception('refresh failed');
        },
      );

      final err = _mockDioException(
        path: '/api/v1/me',
        statusCode: 401,
      );

      Object? passedError;
      final handler = ErrorInterceptorHandler()
        ..next = (e) {
          passedError = e;
        };

      await interceptor.onError(err, handler);
      expect(refreshCallCount, 1);

      // Session should be cleared.
      expect(await tokenStorage.readAccessToken(), isNull);
      expect(await tokenStorage.readRefreshToken(), isNull);
    });

    test('onError - prevents recursive refresh', () async {
      await tokenStorage.saveSession(
        accessToken: 'old-at',
        refreshToken: 'old-rt',
      );

      final interceptor = AuthTokenInterceptor(
        tokenStorage: tokenStorage,
        onRefresh: () async {
          refreshCallCount++;
          throw Exception('refresh failed');
        },
      );

      // First 401 triggers refresh
      final err1 = _mockDioException(
        path: '/api/v1/me',
        statusCode: 401,
      );

      Object? passedError1;
      final handler1 = ErrorInterceptorHandler()
        ..next = (e) {
          passedError1 = e;
        };

      await interceptor.onError(err1, handler1);
      expect(refreshCallCount, 1);

      // Second 401 (retry also fails) should NOT trigger another refresh
      final err2 = _mockDioException(
        path: '/api/v1/me',
        statusCode: 401,
      );

      Object? passedError2;
      final handler2 = ErrorInterceptorHandler()
        ..next = (e) {
          passedError2 = e;
        };

      await interceptor.onError(err2, handler2);
      expect(refreshCallCount, 1); // Still 1 — no second refresh
    });

    test('onError - skips refresh when no refresh token stored', () async {
      // No refresh token stored.
      final interceptor = AuthTokenInterceptor(
        tokenStorage: tokenStorage,
        onRefresh: () async {
          refreshCallCount++;
          return LoginResponse(
            user: UserSummary(
              userId: '',
              email: '',
              roles: [],
              permissions: [],
              createdAt: '',
            ),
            accessToken: 'new',
            refreshToken: 'new-rt',
            expiresIn: 0,
          );
        },
      );

      final err = _mockDioException(
        path: '/api/v1/me',
        statusCode: 401,
      );

      Object? passedError;
      final handler = ErrorInterceptorHandler()
        ..next = (e) {
          passedError = e;
        };

      await interceptor.onError(err, handler);
      expect(refreshCallCount, 0); // No refresh attempted
      expect(passedError, isNotNull); // Original 401 propagated
    });
  });
}
