/// Remote Config — top-level export barrel.
library;

export 'models/remote_config.dart'
    show RemoteConfigStatus, RemoteConfigResponse, RemoteConfigState;
export 'services/config_service.dart' show RemoteConfigService;
export 'services/config_validator.dart' show ConfigValidator;
export 'storage/config_cache_storage.dart' show ConfigCacheStorage;
export 'api/config_api_client.dart' show ConfigApiClient;
export 'config/app_config.dart' show AppConfig;
export 'config/default_config.dart'
    show kDefaultRemoteConfigPayload, kDefaultConfigVersion;
export 'config/platform_info.dart' show PlatformInfo;

/// Auth — top-level export barrel.
export 'models/auth_models.dart'
    show
        UserSummary,
        TokenPair,
        LoginRequest,
        LoginResponse,
        RegisterRequest,
        RegisterResponse,
        AuthState,
        AuthNotifierState;
export 'services/auth_service.dart' show AuthService;
export 'storage/token_storage.dart' show TokenStorage;
export 'api/auth_api_client.dart' show AuthApiClient;
export 'api/mock_auth_api_client.dart' show MockAuthApiClient, DioStateException;
export 'api/real_auth_api_client.dart' show RealAuthApiClient;
