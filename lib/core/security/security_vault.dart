import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure token vault using Android KeyStore & iOS Keychain
class SecurityVault {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const String _keySessionToken = 'bb_session_token';
  static const String _keyRefreshToken = 'bb_refresh_token';
  static const String _keyUserId = 'bb_user_id';
  static const String _keyActiveRoles = 'bb_active_roles';

  static Future<void> saveAuthTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await _storage.write(key: _keySessionToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    await _storage.write(key: _keyUserId, value: userId);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _keySessionToken);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  static Future<void> clearAuth() async {
    await _storage.delete(key: _keySessionToken);
    await _storage.delete(key: _keyRefreshToken);
    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyActiveRoles);
  }

  /// Obfuscate coordinate for privacy-safe caching
  static double obfuscateCoordinate(double coord) {
    // Round to 2 decimal places (~1.1 km resolution)
    return double.parse(coord.toStringAsFixed(2));
  }
}
