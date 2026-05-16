import 'package:flutter_test/flutter_test.dart';
import 'package:livemask_app/models/remote_config.dart';
import 'package:livemask_app/storage/config_cache_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ConfigCacheStorage', () {
    late SharedPreferences prefs;
    late ConfigCacheStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
      storage = ConfigCacheStorage(prefs: prefs);
    });

    final sampleResponse = RemoteConfigResponse(
      schemaVersion: '1.0',
      configKey: 'client.remote_config',
      configVersion: 5,
      configHash:
          'sha256:abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890',
      payload: {'connection': {'recommendation_ttl_seconds': 60}},
      publishedAt: '2026-05-16T12:00:00Z',
    );

    test('save and read back last-known-good', () async {
      await storage.saveLastKnownGood(sampleResponse);

      final cached = storage.readLastKnownGood();
      expect(cached, isNotNull);
      expect(cached!.configVersion, 5);
      expect(cached.configKey, 'client.remote_config');
      expect(cached.payload['connection']['recommendation_ttl_seconds'], 60);
      expect(cached.publishedAt, '2026-05-16T12:00:00Z');
    });

    test('readLastKnownGood returns null when no cache', () {
      final cached = storage.readLastKnownGood();
      expect(cached, isNull);
    });

    test('readLastKnownGood returns null for corrupt data', () async {
      // Manually inject invalid JSON.
      await prefs.setString('remote_config_cache.response', '{invalid json');
      final cached = storage.readLastKnownGood();
      expect(cached, isNull);
    });

    test('readCachedVersion returns 0 when no cache', () {
      expect(storage.readCachedVersion(), 0);
    });

    test('readCachedVersion returns stored version', () async {
      await storage.saveLastKnownGood(sampleResponse);
      expect(storage.readCachedVersion(), 5);
    });

    test('readCachedTimestamp returns null when no cache', () {
      expect(storage.readCachedTimestamp(), isNull);
    });

    test('readCachedTimestamp returns stored timestamp', () async {
      await storage.saveLastKnownGood(sampleResponse);
      final ts = storage.readCachedTimestamp();
      expect(ts, isNotNull);
      // Should be within the last few seconds.
      expect(
        DateTime.now().difference(ts!).inSeconds,
        lessThan(5),
      );
    });

    test('clearCache removes all cached data', () async {
      await storage.saveLastKnownGood(sampleResponse);
      expect(storage.hasCache, true);

      await storage.clearCache();
      expect(storage.hasCache, false);
      expect(storage.readCachedVersion(), 0);
      expect(storage.readCachedTimestamp(), isNull);
    });

    test('hasCache returns false on fresh storage', () {
      expect(storage.hasCache, false);
    });

    test('hasCache returns true after save', () async {
      await storage.saveLastKnownGood(sampleResponse);
      expect(storage.hasCache, true);
    });

    test('cache is overwritten by newer config', () async {
      final v1 = RemoteConfigResponse(
        schemaVersion: '1.0',
        configKey: 'client.remote_config',
        configVersion: 1,
        configHash:
            'sha256:1111111111111111111111111111111111111111111111111111111111111111',
        payload: {'connection': {'recommendation_ttl_seconds': 30}},
      );

      final v2 = RemoteConfigResponse(
        schemaVersion: '1.0',
        configKey: 'client.remote_config',
        configVersion: 2,
        configHash:
            'sha256:2222222222222222222222222222222222222222222222222222222222222222',
        payload: {'connection': {'recommendation_ttl_seconds': 120}},
      );

      await storage.saveLastKnownGood(v1);
      expect(storage.readCachedVersion(), 1);

      await storage.saveLastKnownGood(v2);
      expect(storage.readCachedVersion(), 2);
      expect(storage.readLastKnownGood()!.configVersion, 2);
      expect(
        storage.readLastKnownGood()!
            .payload['connection']['recommendation_ttl_seconds'],
        120,
      );
    });
  });
}
