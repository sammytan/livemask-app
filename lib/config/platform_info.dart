import 'dart:io';

/// Provides current platform info for the config API request.
class PlatformInfo {
  const PlatformInfo({
    required this.clientVersion,
    required this.platform,
  });

  final String clientVersion;
  final String platform;

  static PlatformInfo current() {
    String platformName;
    if (Platform.isIOS) {
      platformName = 'ios';
    } else if (Platform.isAndroid) {
      platformName = 'android';
    } else if (Platform.isMacOS) {
      platformName = 'macos';
    } else if (Platform.isWindows) {
      platformName = 'windows';
    } else if (Platform.isLinux) {
      platformName = 'linux';
    } else {
      platformName = 'unknown';
    }

    // In production this would read from package_info_plus or similar.
    const version = String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0');

    return PlatformInfo(
      clientVersion: version,
      platform: platformName,
    );
  }
}
