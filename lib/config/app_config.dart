/// Runtime app configuration driven by build flavors / --dart-define.
///
/// ## Usage
///
/// ```bash
/// # mock (default, development)
/// flutter run --dart-define=AUTH_CLIENT_MODE=mock
///
/// # real backend
/// flutter run --dart-define=AUTH_CLIENT_MODE=real \
///   --dart-define=API_BASE_URL=https://api.livemask.dev
/// ```
class AppConfig {
  AppConfig._();

  /// The mode for the auth API client: `mock` or `real`.
  ///
  /// Defaults to `mock` for local development.
  /// Pass `--dart-define=AUTH_CLIENT_MODE=real` in CI / release builds.
  static String get authClientMode =>
      const String.fromEnvironment('AUTH_CLIENT_MODE', defaultValue: 'mock');

  /// Whether to use the mock client.
  static bool get useMockAuthClient => authClientMode == 'mock';

  /// The backend base URL without trailing `/`.
  ///
  /// Defaults to empty string (relative) for local dev with proxy.
  /// Pass `--dart-define=API_BASE_URL=https://api.livemask.dev` for staging / prod.
  static String get apiBaseUrl =>
      const String.fromEnvironment('API_BASE_URL', defaultValue: '');

  /// Dio connect timeout in seconds.
  static int get connectTimeoutSeconds =>
      _intFromEnv('CONNECT_TIMEOUT_SECONDS', defaultValue: 10);

  /// Dio receive timeout in seconds.
  static int get receiveTimeoutSeconds =>
      _intFromEnv('RECEIVE_TIMEOUT_SECONDS', defaultValue: 10);

  static int _intFromEnv(String key, {required int defaultValue}) {
    final raw = String.fromEnvironment(key);
    if (raw.isEmpty) return defaultValue;
    return int.tryParse(raw) ?? defaultValue;
  }
}
