/// Built-in default remote config — the ultimate fallback when
/// no last-known-good cache exists and the Backend is unreachable.
///
/// These values match the schema defined in core-configs.md and
/// are designed to keep the App safe and functional in degraded mode.
const Map<String, dynamic> kDefaultRemoteConfigPayload = {
  'schema_version': '1.0',
  'connection': {
    'recommendation_ttl_seconds': 60,
    'fallback_max_attempts': 3,
  },
  'feature_flags': {
    'quick_feedback_enabled': true,
    'connection_quality_report_enabled': true,
  },
};

/// The default config_version for a fresh / never-fetched state.
const int kDefaultConfigVersion = 0;
