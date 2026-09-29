import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Single source of truth untuk secure storage di seluruh aplikasi.
class SecureStorageService {
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUserId = 'user_id';
  static const _kDeviceRegistered = 'device_registered';
  static const _kHmacKey = 'hmac_key';
  static const _kPrivateKey = 'private_key';
  static const _kPublicKey = 'public_key';
  static const _kDeviceId = 'device_id';

  static const _androidOptions = AndroidOptions(
    migrateOnAlgorithmChange: true,
  );
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  );

  final FlutterSecureStorage _storage;

  const SecureStorageService([FlutterSecureStorage? storage])
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: _androidOptions,
            iOptions: _iosOptions,
          );

  Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _kAccessToken, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _kRefreshToken, value: token);

  Future<String?> getUserId() => _storage.read(key: _kUserId);

  Future<void> saveUserId(String userId) =>
      _storage.write(key: _kUserId, value: userId);

  Future<void> saveAuthSession({
    required String accessToken,
    String? refreshToken,
    String? userId,
  }) async {
    await saveAccessToken(accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await saveRefreshToken(refreshToken);
    }
    if (userId != null && userId.isNotEmpty) {
      await saveUserId(userId);
    }
  }

  Future<void> clearAuthSession() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kUserId);
  }

  Future<String?> getDeviceRegistered() => _storage.read(key: _kDeviceRegistered);
  Future<void> saveDeviceRegistered(String value) => _storage.write(key: _kDeviceRegistered, value: value);
  Future<void> deleteDeviceRegistered() => _storage.delete(key: _kDeviceRegistered);

  Future<String?> getHmacKey() => _storage.read(key: _kHmacKey);
  Future<void> saveHmacKey(String value) => _storage.write(key: _kHmacKey, value: value);

  Future<String?> getPrivateKey() => _storage.read(key: _kPrivateKey);
  Future<void> savePrivateKey(String value) => _storage.write(key: _kPrivateKey, value: value);

  Future<String?> getPublicKey() => _storage.read(key: _kPublicKey);
  Future<void> savePublicKey(String value) => _storage.write(key: _kPublicKey, value: value);

  Future<String?> getDeviceId() => _storage.read(key: _kDeviceId);
  Future<void> saveDeviceId(String value) => _storage.write(key: _kDeviceId, value: value);
}
