import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/config_api_client.dart';
import '../models/remote_config.dart';
import '../services/config_service.dart';
import '../services/config_validator.dart';
import '../storage/config_cache_storage.dart';

// --- Low-level dependency providers ---

/// Dio instance for API calls.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));
  return dio;
});

/// SharedPreferences instance.
final sharedPrefsProvider = FutureProvider<SharedPreferences>(
  (_) async => SharedPreferences.getInstance(),
);

/// Config API client — injected with Dio.
final configApiClientProvider = Provider<ConfigApiClient>((ref) {
  return ConfigApiClient(
    httpClient: ref.watch(dioProvider),
    baseUrl: '',
  );
});

/// Config cache storage — injected with SharedPreferences.
final configCacheStorageProvider = FutureProvider<ConfigCacheStorage>((ref) async {
  final prefs = await ref.watch(sharedPrefsProvider.future);
  return ConfigCacheStorage(prefs: prefs);
});

/// Config validator.
final configValidatorProvider = Provider<ConfigValidator>((ref) {
  return const ConfigValidator();
});

/// Remote config service — assembled from above dependencies.
final remoteConfigServiceProvider = FutureProvider<RemoteConfigService>((ref) async {
  final apiClient = ref.watch(configApiClientProvider);
  final cacheStorage = await ref.watch(configCacheStorageProvider.future);
  final validator = ref.watch(configValidatorProvider);
  return RemoteConfigService(
    apiClient: apiClient,
    cacheStorage: cacheStorage,
    validator: validator,
  );
});

// --- Stateful config state provider ---

/// The current [RemoteConfigState] — updated by [configNotifierProvider].
///
/// Starts as [RemoteConfigState.initial] and is populated:
/// - On app startup via [ConfigNotifier.loadCached].
/// - On manual refresh via [ConfigNotifier.refresh].
final configStateProvider =
    StateNotifierProvider<ConfigNotifier, RemoteConfigState>((ref) {
  return ConfigNotifier(ref);
});

/// Notifier that manages [RemoteConfigState] transitions.
class ConfigNotifier extends StateNotifier<RemoteConfigState> {
  ConfigNotifier(this._ref) : super(RemoteConfigState.initial);

  final Ref _ref;

  RemoteConfigService? _service;

  Future<RemoteConfigService> _getService() async {
    _service ??= await _ref.read(remoteConfigServiceProvider.future);
    return _service!;
  }

  /// Loads cached config on app startup (lightweight, no network).
  Future<void> loadCached() async {
    final service = await _getService();
    final cachedState = service.loadCachedState();
    state = cachedState;
  }

  /// Fetches fresh config from Backend, validates, caches, or falls back.
  Future<void> refresh() async {
    final service = await _getService();
    state = RemoteConfigState.initial;
    state = await service.refreshConfig();
  }
}
