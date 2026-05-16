import 'package:flutter_test/flutter_test.dart';
import 'package:livemask_app/models/remote_config.dart';
import 'package:livemask_app/services/config_validator.dart';

void main() {
  late ConfigValidator validator;

  setUp(() {
    validator = const ConfigValidator();
  });

  group('ConfigValidator', () {
    final validResponse = RemoteConfigResponse(
      schemaVersion: '1.0',
      configKey: 'client.remote_config',
      configVersion: 3,
      configHash:
          'sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      payload: <String, dynamic>{},
    );

    test('accepts a valid response', () {
      final result = validator.validate(validResponse);
      expect(result.isValid, true);
      expect(result.errorMessage, isNull);
    });

    test('rejects wrong config_key', () {
      final response = validResponse.copyWith(
        configKey: 'nodeagent.runtime_config',
      );
      final result = validator.validate(response);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('config_key mismatch'));
    });

    test('rejects empty config_hash', () {
      final response = validResponse.copyWith(configHash: '');
      final result = validator.validate(response);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('config_hash is empty'));
    });

    test('rejects config_hash without sha256: prefix', () {
      final response = validResponse.copyWith(
        configHash: 'md5:d41d8cd98f00b204e9800998ecf8427e',
      );
      final result = validator.validate(response);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('must start with'));
    });

    test('rejects config_hash with invalid hex length', () {
      final response = validResponse.copyWith(
        configHash: 'sha256:abc123',
      );
      final result = validator.validate(response);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('not a valid SHA-256'));
    });

    test('rejects config_hash with non-hex characters', () {
      final response = validResponse.copyWith(
        configHash: 'sha256:zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz'
            'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz',
      );
      final result = validator.validate(response);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('not a valid SHA-256'));
    });

    test('rejects negative config_version', () {
      final response = validResponse.copyWith(configVersion: -1);
      final result = validator.validate(response);
      expect(result.isValid, false);
    });

    test('rejects empty schema_version', () {
      final response = validResponse.copyWith(schemaVersion: '');
      final result = validator.validate(response);
      expect(result.isValid, false);
      expect(result.errorMessage, contains('schema_version is empty'));
    });

    test('verifies payload hash matches claimed hash', () {
      final payload = <String, dynamic>{
        'connection': {
          'recommendation_ttl_seconds': 60,
        },
      };
      // The canonical JSON is: {"connection":{"recommendation_ttl_seconds":60}}
      // SHA-256 of that:
      const expectedHash =
          'sha256:f88fd88e0e0d9ccf1ae09bbaa0b5e34eab7e0c5b0aaa2d5e85b3ffa6a3c5d36e';

      final result = validator.verifyPayloadHash(payload, expectedHash);
      expect(result, true);
    });

    test('detects payload hash mismatch', () {
      final payload = <String, dynamic>{'foo': 'bar'};
      const wrongHash =
          'sha256:ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff';

      final result = validator.verifyPayloadHash(payload, wrongHash);
      expect(result, false);
    });

    test('returns false for hash without sha256: prefix', () {
      final payload = <String, dynamic>{};
      final result = validator.verifyPayloadHash(payload, 'md5:abc123');
      expect(result, false);
    });
  });
}

/// Extension to copy with overrides for testing.
extension _CopyRemoteConfigResponse on RemoteConfigResponse {
  RemoteConfigResponse copyWith({
    String? schemaVersion,
    String? configKey,
    int? configVersion,
    String? configHash,
    Map<String, dynamic>? payload,
    String? fallbackAction,
    String? publishedAt,
  }) {
    return RemoteConfigResponse(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      configKey: configKey ?? this.configKey,
      configVersion: configVersion ?? this.configVersion,
      configHash: configHash ?? this.configHash,
      payload: payload ?? this.payload,
      fallbackAction: fallbackAction ?? this.fallbackAction,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }
}
