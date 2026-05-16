/// Remote Config — top-level export barrel.
///
/// Consumers only need:
/// ```dart
/// import 'package:livemask_app/remote_config.dart';
/// ```
library;

export 'models/remote_config.dart' show RemoteConfigStatus, RemoteConfigResponse, RemoteConfigState;
export 'services/config_service.dart' show RemoteConfigService;
export 'services/config_validator.dart' show ConfigValidator;
export 'storage/config_cache_storage.dart' show ConfigCacheStorage;
export 'api/config_api_client.dart' show ConfigApiClient;
export 'config/default_config.dart' show kDefaultRemoteConfigPayload, kDefaultConfigVersion;
export 'config/platform_info.dart' show PlatformInfo;
