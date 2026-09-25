import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Refresh/access tokens live ONLY in platform secure storage.
/// Nothing token-like goes into SharedPreferences, logs, or analytics.
class SecureTokenStorage {
  SecureTokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kAccess = 'egt_access_token';
  static const _kRefresh = 'egt_refresh_token';
  static const _kDeviceId = 'egt_device_id';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: _kAccess, value: accessToken);
    await _storage.write(key: _kRefresh, value: refreshToken);
  }

  Future<String?> readAccessToken() => _storage.read(key: _kAccess);
  Future<String?> readRefreshToken() => _storage.read(key: _kRefresh);

  Future<void> clearTokens() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }

  Future<String?> readDeviceId() => _storage.read(key: _kDeviceId);
  Future<void> saveDeviceId(String id) => _storage.write(key: _kDeviceId, value: id);

  /// Wipes ALL secure storage (logout incl. "log out of all devices" local cleanup).
  Future<void> wipe() => _storage.deleteAll();
}
