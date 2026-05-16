import 'package:dio/dio.dart';
import '../api/config_api_client.dart';
import '../config/default_config.dart';
import '../config/platform_info.dart';
import '../models/remote_config.dart';
import '../storage/config_cache_storage.dart';
import 'config_validator.dart';

/// Core service for remote config lifecycle:
///
/// 1. Fetch from Backend via [ConfigApiClient].
/// 2. Validate schema / hash / version / key.
/// 3. Persist to last-known-good cache on success.
/// 4. Fall back to cache on network failure, non-200, or invalid payload.
/// 5. Fall back to built-in defaults when no cache exists.
///
/// The service is stateless except for the injected dependencies.
/// Stateful config status tracking is done at the provider layer.
class RemoteConfigService {
  RemoteConfigService({
    required ConfigApiClient apiClient,
    required ConfigCacheStorage cacheStorage,
    required ConfigValidator validator,
    this.timeoutSeconds = 10,
  })  : _apiClient = apiClient,
        _cacheStorage = cacheStorage,
        _validator = validator;

  final ConfigApiClient _apiClient;
  final ConfigCacheStorage _cacheStorage;
  final ConfigValidator _validator;
  final int timeoutSeconds;

  /// Attempts a full fetch -> validate -> cache cycle.
  ///
  /// Returns a [RemoteConfigState] that reflects the outcome. This method
  /// NEVER throws; all errors are caught and translated into fallback states.
  Future<RemoteConfigState> refreshConfig() async {
    final platformInfo = PlatformInfo.current();
    final localCachedVersion = _cacheStorage.readCachedVersion();

    try {
      // --- Phase 1: Fetch ---
      final response = await _apiClient.fetchClientConfig(
        platformInfo: platformInfo,
        localConfigVersion: localCachedVersion,
      ).timeout(
        Duration(seconds: timeoutSeconds),
      );

      // --- Phase 2: Validate ---
      final validation = _validator.validate(response);
      if (!validation.isValid) {
        // Remote response is malformed — fall back to cache or defaults.
        return _buildFallbackState(
          status: RemoteConfigStatus.invalid,
          errorMessage: validation.errorMessage,
        );
      }

      // --- Phase 3: Persist as last-known-good ---
      await _cacheStorage.saveLastKnownGood(response);

      return RemoteConfigState(
        response: response,
        status: RemoteConfigStatus.current,
        lastUpdatedAt: DateTime.now(),
      );
    } on DioException catch (e) {
      // Network / timeout / non-200 — fall back.
      final message = _summarizeDioError(e);
      return _buildFallbackState(
        status: RemoteConfigStatus.fallback,
        errorMessage: message,
      );
    } catch (e) {
      // Unexpected error — fall back.
      return _buildFallbackState(
        status: RemoteConfigStatus.fallback,
        errorMessage: 'Unexpected error: $e',
      );
    }
  }

  /// Reads the last-known-good from cache without hitting the network.
  RemoteConfigState loadCachedState() {
    final cached = _cacheStorage.readLastKnownGood();
    final timestamp = _cacheStorage.readCachedTimestamp();

    if (cached != null) {
      return RemoteConfigState(
        response: cached,
        status: RemoteConfigStatus.current,
        lastUpdatedAt: timestamp,
      );
    }

    return RemoteConfigState.initial;
  }

  /// Reads individual config values for consumers.
  int getRecommendationTtlSeconds([RemoteConfigState? state]) {
    final payload = state?.payload ?? kDefaultRemoteConfigPayload;
    return payload['connection']?['recommendation_ttl_seconds'] as int? ??
        kDefaultRemoteConfigPayload['connection']!['recommendation_ttl_seconds']
            as int;
  }

  int getFallbackMaxAttempts([RemoteConfigState? state]) {
    final payload = state?.payload ?? kDefaultRemoteConfigPayload;
    return payload['connection']?['fallback_max_attempts'] as int? ??
        kDefaultRemoteConfigPayload['connection']!['fallback_max_attempts']
            as int;
  }

  bool isQuickFeedbackEnabled([RemoteConfigState? state]) {
    final payload = state?.payload ?? kDefaultRemoteConfigPayload;
    return payload['feature_flags']?['quick_feedback_enabled'] as bool? ??
        kDefaultRemoteConfigPayload['feature_flags']!['quick_feedback_enabled']
            as bool;
  }

  bool isConnectionQualityReportEnabled([RemoteConfigState? state]) {
    final payload = state?.payload ?? kDefaultRemoteConfigPayload;
    return payload['feature_flags']
            ?['connection_quality_report_enabled'] as bool? ??
        kDefaultRemoteConfigPayload['feature_flags']!
            ['connection_quality_report_enabled'] as bool;
  }

  // --- Private helpers ---

  RemoteConfigState _buildFallbackState({
    required RemoteConfigStatus status,
    String? errorMessage,
  }) {
    final cached = _cacheStorage.readLastKnownGood();

    if (cached != null) {
      return RemoteConfigState(
        response: cached,
        status: status,
        lastUpdatedAt: _cacheStorage.readCachedTimestamp(),
        errorMessage: errorMessage,
      );
    }

    // No cache exists — use built-in defaults.
    return RemoteConfigState(
      response: RemoteConfigResponse(
        schemaVersion: '1.0',
        configKey: 'client.remote_config',
        configVersion: kDefaultConfigVersion,
        configHash: '',
        payload: Map<String, dynamic>.from(kDefaultRemoteConfigPayload),
      ),
      status: RemoteConfigStatus.degraded,
      errorMessage: errorMessage,
    );
  }

  String _summarizeDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out';
      case DioExceptionType.connectionError:
        return 'Connection failed: ${e.message}';
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        return 'Backend returned HTTP $statusCode';
      case DioExceptionType.cancel:
        return 'Request was cancelled';
      default:
        return 'Network error: ${e.message}';
    }
  }
}
