import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/remote_config.dart';

/// Validates a [RemoteConfigResponse] against rules from the config contract.
///
/// Rules applied:
/// 1. `config_key` must be `"client.remote_config"`.
/// 2. `config_hash` must be present and match `sha256:` prefix pattern.
/// 3. `config_version` must be >= 0 (strictly > 0 for published configs).
/// 4. `schema_version` must be present (currently "1.0" is the only known value;
///    unknown versions are tolerated but logged).
class ConfigValidator {
  const ConfigValidator();

  static const String expectedConfigKey = 'client.remote_config';
  static const String hashPrefix = 'sha256:';
  static const String knownSchemaVersion = '1.0';

  ConfigValidationResult validate(RemoteConfigResponse response) {
    // 1. config_key check
    if (response.configKey != expectedConfigKey) {
      return ConfigValidationResult.invalid(
        'config_key mismatch: expected "$expectedConfigKey", '
        'got "${response.configKey}"',
      );
    }

    // 2. config_hash check
    if (response.configHash.isEmpty) {
      return ConfigValidationResult.invalid(
        'config_hash is empty',
      );
    }
    if (!response.configHash.startsWith(hashPrefix)) {
      return ConfigValidationResult.invalid(
        'config_hash must start with "$hashPrefix", '
        'got "${response.configHash}"',
      );
    }
    final hexPart = response.configHash.substring(hashPrefix.length);
    if (hexPart.length != 64 || !RegExp(r'^[a-f0-9]{64}$').hasMatch(hexPart)) {
      return ConfigValidationResult.invalid(
        'config_hash hex part is not a valid SHA-256: '
        '"$hexPart"',
      );
    }

    // 3. config_version check
    if (response.configVersion < 0) {
      return ConfigValidationResult.invalid(
        'config_version must be >= 0, got ${response.configVersion}',
      );
    }

    // 4. schema_version check (tolerate unknown but warn)
    if (response.schemaVersion.isEmpty) {
      return ConfigValidationResult.invalid(
        'schema_version is empty',
      );
    }

    return ConfigValidator.valid;
  }

  /// Verifies that the payload's actual SHA-256 hash matches the claimed hash.
  bool verifyPayloadHash(
    Map<String, dynamic> payload,
    String claimedHash,
  ) {
    if (!claimedHash.startsWith(hashPrefix)) return false;
    final canonical = jsonEncode(_canonicalize(payload));
    final digest = sha256.convert(utf8.encode(canonical)).toString();
    return digest == claimedHash.substring(hashPrefix.length);
  }

  /// Recursively sorts map keys to produce a canonical JSON representation.
  Map<String, dynamic> _canonicalize(Map<String, dynamic> map) {
    final sorted = <String, dynamic>{};
    final keys = map.keys.toList()..sort();
    for (final key in keys) {
      final value = map[key];
      if (value is Map<String, dynamic>) {
        sorted[key] = _canonicalize(value);
      } else {
        sorted[key] = value;
      }
    }
    return sorted;
  }
}
