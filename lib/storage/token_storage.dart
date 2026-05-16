import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Platform-secure token storage for JWT access and refresh tokens.
///
/// Uses [FlutterSecureStorage] which maps to:
/// - iOS: Keychain (kSecClassGenericPassword)
/// - Android: EncryptedSharedPreferences
/// - macOS: Keychain
/// - Windows: DPAPI via Credential Manager
/// - Linux: libsecret
class TokenStorage {
  TokenStorage({FlutterSecureStorage? secureStorage})
      : _storage =
            secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _accessTokenKey = 'auth_access_token';
  static const String _refreshTokenKey = 'auth_refresh_token';
  static const String _userIdKey = 'auth_user_id';

  // --- Access Token ---

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> readAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }

  // --- Refresh Token ---

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> readRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }

  // --- User ID (cached for quick lookup) ---

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> readUserId() async {
    return _storage.read(key: _userIdKey);
  }

  Future<void> deleteUserId() async {
    await _storage.delete(key: _userIdKey);
  }

  // --- Bulk operations ---

  /// Persists both tokens and user ID in one batch.
  Future<void> saveSession({
    required String accessToken,
    String? refreshToken,
    String? userId,
  }) async {
    await saveAccessToken(accessToken);
    if (refreshToken != null) {
      await saveRefreshToken(refreshToken);
    }
    if (userId != null) {
      await saveUserId(userId);
    }
  }

  /// Clears all stored auth tokens and user ID.
  Future<void> clearSession() async {
    await deleteAccessToken();
    await deleteRefreshToken();
    await deleteUserId();
  }

  /// Whether a stored access token exists (does not validate expiry).
  Future<bool> hasSession() async {
    final token = await readAccessToken();
    return token != null && token.isNotEmpty;
  }
}
