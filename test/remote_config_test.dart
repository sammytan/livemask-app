import 'package:flutter_test/flutter_test.dart';
import 'package:livemask_app/models/remote_config.dart';

void main() {
  group('RemoteConfigResponse', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'schema_version': '1.0',
        'config_key': 'client.remote_config',
        'config_version': 3,
        'config_hash':
            'sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        'payload': {'connection': {'recommendation_ttl_seconds': 60}},
        'fallback_action': 'continue',
        'published_at': '2026-05-16T12:00:00Z',
      };

      final response = RemoteConfigResponse.fromJson(json);

      expect(response.schemaVersion, '1.0');
      expect(response.configKey, 'client.remote_config');
      expect(response.configVersion, 3);
      expect(
        response.configHash,
        'sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
      expect(response.payload['connection']['recommendation_ttl_seconds'], 60);
      expect(response.fallbackAction, 'continue');
      expect(response.publishedAt, '2026-05-16T12:00:00Z');
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'schema_version': '1.0',
        'config_key': 'client.remote_config',
        'config_version': 1,
        'config_hash':
            'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'payload': {},
      };

      final response = RemoteConfigResponse.fromJson(json);

      expect(response.fallbackAction, isNull);
      expect(response.publishedAt, isNull);
    });

    test('fromJson handles null payload gracefully', () {
      final json = {
        'schema_version': '1.0',
        'config_key': 'client.remote_config',
        'config_version': 1,
        'config_hash':
            'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'payload': null,
      };

      final response = RemoteConfigResponse.fromJson(json);

      expect(response.payload, <String, dynamic>{});
    });

    test('toJson produces round-trippable output', () {
      final original = RemoteConfigResponse(
        schemaVersion: '1.0',
        configKey: 'client.remote_config',
        configVersion: 3,
        configHash:
            'sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        payload: {'key': 'value'},
        fallbackAction: 'continue',
        publishedAt: '2026-05-16T12:00:00Z',
      );

      final json = original.toJson();
      final restored = RemoteConfigResponse.fromJson(json);

      expect(restored.schemaVersion, original.schemaVersion);
      expect(restored.configKey, original.configKey);
      expect(restored.configVersion, original.configVersion);
      expect(restored.configHash, original.configHash);
      expect(restored.payload['key'], 'value');
      expect(restored.fallbackAction, 'continue');
      expect(restored.publishedAt, '2026-05-16T12:00:00Z');
    });

    test('toJson omits null optional fields', () {
      final response = RemoteConfigResponse(
        schemaVersion: '1.0',
        configKey: 'client.remote_config',
        configVersion: 1,
        configHash:
            'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        payload: {},
      );

      final json = response.toJson();
      expect(json.containsKey('fallback_action'), false);
      expect(json.containsKey('published_at'), false);
    });
  });

  group('RemoteConfigState', () {
    test('initial state has no config', () {
      final state = RemoteConfigState.initial;
      expect(state.status, RemoteConfigStatus.none);
      expect(state.hasValidConfig, false);
      expect(state.configVersion, 0);
      expect(state.payload, <String, dynamic>{});
    });

    test('copyWith preserves existing values', () {
      final response = RemoteConfigResponse(
        schemaVersion: '1.0',
        configKey: 'client.remote_config',
        configVersion: 2,
        configHash:
            'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        payload: {'key': 'value'},
      );

      final state = RemoteConfigState(
        response: response,
        status: RemoteConfigStatus.current,
        lastUpdatedAt: DateTime(2026, 5, 16),
      );

      final copied = state.copyWith();
      expect(copied.response, response);
      expect(copied.status, RemoteConfigStatus.current);
      expect(copied.lastUpdatedAt, DateTime(2026, 5, 16));
    });

    test('copyWith with clearResponse=true clears response', () {
      final state = RemoteConfigState(
        response: RemoteConfigResponse(
          schemaVersion: '1.0',
          configKey: 'client.remote_config',
          configVersion: 1,
          configHash: '',
          payload: {},
        ),
        status: RemoteConfigStatus.current,
      );

      final cleared = state.copyWith(clearResponse: true, status: RemoteConfigStatus.none);
      expect(cleared.response, isNull);
      expect(cleared.status, RemoteConfigStatus.none);
    });

    test('isUsingDefaults is true for degraded and none', () {
      expect(
        RemoteConfigState(status: RemoteConfigStatus.degraded).isUsingDefaults,
        true,
      );
      expect(
        RemoteConfigState(status: RemoteConfigStatus.none).isUsingDefaults,
        true,
      );
      expect(
        RemoteConfigState(status: RemoteConfigStatus.current).isUsingDefaults,
        false,
      );
    });

    test('hasValidConfig is true when response is present', () {
      final state = RemoteConfigState(
        response: RemoteConfigResponse(
          schemaVersion: '1.0',
          configKey: 'client.remote_config',
          configVersion: 1,
          configHash: '',
          payload: {},
        ),
        status: RemoteConfigStatus.current,
      );
      expect(state.hasValidConfig, true);
    });
  });
}
