import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/remote_config.dart';

/// Persistent last-known-good cache for remote config using SharedPreferences.
///
/// The cache is purely a read/write store — validation is the caller's
/// responsibility. This keeps the storage layer simple and testable.
class ConfigCacheStorage {
  ConfigCacheStorage({required SharedPreferences prefs})
      : _prefs = prefs;

  final SharedPreferences _prefs;

  static const String _cacheKeyPrefix = 'remote_config_cache';
  static const String _cacheResponseKey = '$_cacheKeyPrefix.response';
  static const String _cacheVersionKey = '$_cacheKeyPrefix.version';
  static const String _cacheTimestampKey = '$_cacheKeyPrefix.timestamp';

  /// Persists a validated [RemoteConfigResponse] to local storage.
  Future<void> saveLastKnownGood(RemoteConfigResponse response) async {
    final jsonStr = jsonEncode(response.toJson());
    await _prefs.setString(_cacheResponseKey, jsonStr);
    await _prefs.setInt(_cacheVersionKey, response.configVersion);
    await _prefs.setInt(
      _cacheTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Reads the last-known-good [RemoteConfigResponse] from local storage.
  ///
  /// Returns `null` if no cache exists or the stored data is corrupt.
  RemoteConfigResponse? readLastKnownGood() {
    final jsonStr = _prefs.getString(_cacheResponseKey);
    if (jsonStr == null || jsonStr.isEmpty) return null;

    try {
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      return RemoteConfigResponse.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Returns the cached config version, or 0 if no cache exists.
  int readCachedVersion() {
    return _prefs.getInt(_cacheVersionKey) ?? 0;
  }

  /// Returns the timestamp of the last successful cache write, or null.
  DateTime? readCachedTimestamp() {
    final ms = _prefs.getInt(_cacheTimestampKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Clears the entire config cache (e.g. on logout or forced reset).
  Future<void> clearCache() async {
    await _prefs.remove(_cacheResponseKey);
    await _prefs.remove(_cacheVersionKey);
    await _prefs.remove(_cacheTimestampKey);
  }

  /// Whether a cached config exists.
  bool get hasCache => _prefs.containsKey(_cacheResponseKey);
}
