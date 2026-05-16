/// Describes the health / source of the currently applied remote config.
enum RemoteConfigStatus {
  /// The latest remote config is applied and matches the Backend.
  current,

  /// A newer version exists on the Backend; local is still usable.
  stale,

  /// Using last-known-good because the network / Backend was unavailable.
  fallback,

  /// Using last-known-good because the remote response failed validation.
  invalid,

  /// No last-known-good exists and Backend is unreachable;
  /// built-in defaults are in use.
  degraded,

  /// No config has been loaded yet.
  none,
}

/// The parsed response from `GET /api/v1/config/client`.
class RemoteConfigResponse {
  const RemoteConfigResponse({
    required this.schemaVersion,
    required this.configKey,
    required this.configVersion,
    required this.configHash,
    required this.payload,
    this.fallbackAction,
    this.publishedAt,
  });

  factory RemoteConfigResponse.fromJson(Map<String, dynamic> json) {
    return RemoteConfigResponse(
      schemaVersion: json['schema_version'] as String? ?? '',
      configKey: json['config_key'] as String? ?? '',
      configVersion: json['config_version'] as int? ?? 0,
      configHash: json['config_hash'] as String? ?? '',
      payload: json['payload'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : <String, dynamic>{},
      fallbackAction: json['fallback_action'] as String?,
      publishedAt: json['published_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'schema_version': schemaVersion,
        'config_key': configKey,
        'config_version': configVersion,
        'config_hash': configHash,
        'payload': payload,
        if (fallbackAction != null) 'fallback_action': fallbackAction,
        if (publishedAt != null) 'published_at': publishedAt,
      };

  final String schemaVersion;
  final String configKey;
  final int configVersion;
  final String configHash;
  final Map<String, dynamic> payload;
  final String? fallbackAction;
  final String? publishedAt;

  @override
  String toString() =>
      'RemoteConfigResponse(configKey=$configKey, version=$configVersion, '
      'hash=$configHash, schema=$schemaVersion)';
}

/// The result of validating a [RemoteConfigResponse].
class ConfigValidationResult {
  const ConfigValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  final bool isValid;
  final String? errorMessage;

  static const valid = ConfigValidationResult(isValid: true);
  static ConfigValidationResult invalid(String message) =>
      ConfigValidationResult(isValid: false, errorMessage: message);
}

/// Represents the full state of remote config at a point in time.
class RemoteConfigState {
  const RemoteConfigState({
    this.response,
    this.status = RemoteConfigStatus.none,
    this.lastUpdatedAt,
    this.errorMessage,
  });

  final RemoteConfigResponse? response;
  final RemoteConfigStatus status;
  final DateTime? lastUpdatedAt;
  final String? errorMessage;

  int get configVersion => response?.configVersion ?? kFallbackVersion;
  Map<String, dynamic> get payload =>
      response?.payload ?? kFallbackPayload;
  bool get hasValidConfig => response != null;
  bool get isUsingDefaults =>
      status == RemoteConfigStatus.degraded ||
      status == RemoteConfigStatus.none;

  static const initial = RemoteConfigState(status: RemoteConfigStatus.none);

  RemoteConfigState copyWith({
    RemoteConfigResponse? response,
    RemoteConfigStatus? status,
    DateTime? lastUpdatedAt,
    String? errorMessage,
    bool clearResponse = false,
  }) {
    return RemoteConfigState(
      response: clearResponse ? null : (response ?? this.response),
      status: status ?? this.status,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Placeholder for when no real config is available.
/// These are NEVER used in production — they exist to satisfy the type system
/// during the initial "none" state before any fetch attempt.
const int kFallbackVersion = 0;
const Map<String, dynamic> kFallbackPayload = <String, dynamic>{};
