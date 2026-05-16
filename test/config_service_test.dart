import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livemask_app/api/config_api_client.dart';
import 'package:livemask_app/models/remote_config.dart';
import 'package:livemask_app/services/config_service.dart';
import 'package:livemask_app/services/config_validator.dart';
import 'package:livemask_app/storage/config_cache_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A controlled Dio adapter that returns pre-configured responses or throws.
class MockDioAdapter implements HttpClientAdapter {
  MockDioAdapter();

  Map<String, dynamic>? _successResponse;
  DioExceptionType? _errorType;
  int? _statusCode;

  /// When called, return [response] with HTTP 200.
  void onGet(Map<String, dynamic> response) {
    _successResponse = response;
    _errorType = null;
    _statusCode = null;
  }

  /// When called, throw a [DioException] with the given type.
  void onGetError(DioExceptionType type, {int? statusCode}) {
    _successResponse = null;
    _errorType = type;
    _statusCode = statusCode;
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (_errorType != null) {
      throw DioException(
        requestOptions: options,
        type: _errorType!,
        response: _statusCode != null
            ? ResponseBody.fromString(
                '{"error":"mock"}',
                _statusCode!,
              )
            : null,
      );
    }
    if (_successResponse != null) {
      return ResponseBody.fromString(
        jsonEncode(_successResponse),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString('{"error":"not configured"}', 404);
  }

  @override
  void close() {}
}

void main() {
  group('RemoteConfigService', () {
    late SharedPreferences prefs;
    late ConfigCacheStorage cacheStorage;
    late MockDioAdapter adapter;
    late Dio httpClient;
    late ConfigApiClient apiClient;
    late RemoteConfigService service;

    /// Valid hash for empty payload canonical JSON "{}".
    /// SHA-256 of "{}" = 44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a
    static const kEmptyPayloadHash =
        'sha256:44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a';

    /// A valid sample response.
    Map<String, dynamic> validResponseJson({int version = 3}) => {
          'schema_version': '1.0',
          'config_key': 'client.remote_config',
          'config_version': version,
          'config_hash': kEmptyPayloadHash,
          'payload': <String, dynamic>{},
          'published_at': '2026-05-16T12:00:00Z',
        };

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      cacheStorage = ConfigCacheStorage(prefs: prefs);
      adapter = MockDioAdapter();
      httpClient = Dio(BaseOptions())..httpClientAdapter = adapter;
      apiClient = ConfigApiClient(httpClient: httpClient);
      service = RemoteConfigService(
        apiClient: apiClient,
        cacheStorage: cacheStorage,
        validator: const ConfigValidator(),
        timeoutSeconds: 5,
      );
    });

    group('first fetch — no cache', () {
      test('successful fetch returns current status and caches result',
          () async {
        adapter.onGet(validResponseJson(version: 3));

        final state = await service.refreshConfig();

        expect(state.status, RemoteConfigStatus.current);
        expect(state.hasValidConfig, true);
        expect(state.configVersion, 3);

        // Verify cache was written.
        final cached = cacheStorage.readLastKnownGood();
        expect(cached, isNotNull);
        expect(cached!.configVersion, 3);
      });

      test('network timeout returns degraded status (no cache)', () async {
        adapter.onGetError(DioExceptionType.connectionTimeout);

        final state = await service.refreshConfig();

        expect(state.status, RemoteConfigStatus.fallback);
        expect(state.isUsingDefaults, true);
        expect(state.errorMessage, contains('timed out'));
      });

      test('connection error returns degraded status (no cache)', () async {
        adapter.onGetError(DioExceptionType.connectionError);

        final state = await service.refreshConfig();

        expect(state.status, RemoteConfigStatus.fallback);
        expect(state.isUsingDefaults, true);
      });

      test('HTTP 500 returns degraded status (no cache)', () async {
        adapter.onGetError(DioExceptionType.badResponse, statusCode: 500);

        final state = await service.refreshConfig();

        expect(state.status, RemoteConfigStatus.fallback);
        expect(state.isUsingDefaults, true);
        expect(state.errorMessage, contains('500'));
      });

      test('invalid config_key returns invalid status', () async {
        final badKeyJson = validResponseJson()
          ..['config_key'] = 'wrong.key';
        adapter.onGet(badKeyJson);

        final state = await service.refreshConfig();

        expect(state.status, RemoteConfigStatus.invalid);
        expect(state.isUsingDefaults, true);
        expect(state.errorMessage, contains('config_key mismatch'));
      });

      test('missing config_hash returns invalid status', () async {
        final badHashJson = validResponseJson()
          ..['config_hash'] = '';
        adapter.onGet(badHashJson);

        final state = await service.refreshConfig();

        expect(state.status, RemoteConfigStatus.invalid);
        expect(state.isUsingDefaults, true);
        expect(state.errorMessage, contains('config_hash is empty'));
      });

      test('malformed config_hash returns invalid status', () async {
        final badHashJson = validResponseJson()
          ..['config_hash'] = 'sha256:xyz';
        adapter.onGet(badHashJson);

        final state = await service.refreshConfig();

        expect(state.status, RemoteConfigStatus.invalid);
        expect(state.isUsingDefaults, true);
      });

      test('empty schema_version returns invalid status', () async {
        final badSchemaJson = validResponseJson()
          ..['schema_version'] = '';
        adapter.onGet(badSchemaJson);

        final state = await service.refreshConfig();

        expect(state.status, RemoteConfigStatus.invalid);
        expect(state.isUsingDefaults, true);
      });

      test('negative config_version returns invalid status', () async {
        final badVersionJson = validResponseJson()
          ..['config_version'] = -1;
        adapter.onGet(badVersionJson);

        final state = await service.refreshConfig();

        expect(state.status, RemoteConfigStatus.invalid);
        expect(state.isUsingDefaults, true);
      });
    });

    group('with cached last-known-good', () {
      setUp(() async {
        // Seed a "v2" cached config.
        final cached = RemoteConfigResponse(
          schemaVersion: '1.0',
          configKey: 'client.remote_config',
          configVersion: 2,
          configHash:
              'sha256:1111111111111111111111111111111111111111111111111111111111111111',
          payload: {
            'connection': {'recommendation_ttl_seconds': 60},
          },
          publishedAt: '2026-05-15T12:00:00Z',
        );
        await cacheStorage.saveLastKnownGood(cached);
      });

      test('network failure returns fallback with cached config', () async {
        adapter.onGetError(DioExceptionType.connectionTimeout);

        final state = await service.refreshConfig();

        expect(state.status, RemoteConfigStatus.fallback);
        expect(state.isUsingDefaults, false);
        expect(state.hasValidConfig, true);
        expect(state.configVersion, 2);
        expect(
          state.payload['connection']['recommendation_ttl_seconds'],
          60,
        );
      });

      test('HTTP 500 returns fallback with cached config', () async {
        adapter.onGetError(DioExceptionType.badResponse, statusCode: 500);

        final state = await service.refreshConfig();

        expect(state.status, RemoteConfigStatus.fallback);
        expect(state.hasValidConfig, true);
        expect(state.configVersion, 2);
      });

      test('invalid response returns invalid with cached config', () async {
        final badKeyJson = validResponseJson()
          ..['config_key'] = 'wrong.key';
        adapter.onGet(badKeyJson);

        final state = await service.refreshConfig();

        expect(state.status, RemoteConfigStatus.invalid);
        expect(state.hasValidConfig, true);
        expect(state.configVersion, 2);
      });

      test('successful fetch overwrites old cache with newer config',
          () async {
        adapter.onGet(validResponseJson(version: 5));

        final state = await service.refreshConfig();

        expect(state.status, RemoteConfigStatus.current);
        expect(state.configVersion, 5);

        // Verify cache was updated.
        final cached = cacheStorage.readLastKnownGood();
        expect(cached!.configVersion, 5);
      });
    });

    group('loadCachedState', () {
      test('returns initial state when no cache exists', () {
        final state = service.loadCachedState();
        expect(state.status, RemoteConfigStatus.none);
        expect(state.hasValidConfig, false);
      });

      test('returns current state with cached response', () async {
        final cached = RemoteConfigResponse(
          schemaVersion: '1.0',
          configKey: 'client.remote_config',
          configVersion: 3,
          configHash:
              'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          payload: {'connection': {'recommendation_ttl_seconds': 120}},
        );
        await cacheStorage.saveLastKnownGood(cached);

        final state = service.loadCachedState();

        expect(state.status, RemoteConfigStatus.current);
        expect(state.configVersion, 3);
        expect(
          state.payload['connection']['recommendation_ttl_seconds'],
          120,
        );
      });
    });

    group('config value accessors', () {
      test('getRecommendationTtlSeconds returns default when no state', () {
        final ttl = service.getRecommendationTtlSeconds();
        expect(ttl, 60);
      });

      test('getRecommendationTtlSeconds reads from state payload', () {
        final state = RemoteConfigState(
          response: RemoteConfigResponse(
            schemaVersion: '1.0',
            configKey: 'client.remote_config',
            configVersion: 1,
            configHash: '',
            payload: {
              'connection': {'recommendation_ttl_seconds': 120},
            },
          ),
          status: RemoteConfigStatus.current,
        );
        expect(service.getRecommendationTtlSeconds(state), 120);
      });

      test('getFallbackMaxAttempts returns default', () {
        expect(service.getFallbackMaxAttempts(), 3);
      });

      test('isQuickFeedbackEnabled returns default', () {
        expect(service.isQuickFeedbackEnabled(), true);
      });

      test('isConnectionQualityReportEnabled returns default', () {
        expect(service.isConnectionQualityReportEnabled(), true);
      });
    });
  });
}
