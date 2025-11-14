import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper around [FlutterSecureStorage] for auth-related secrets.
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyTokenExpiry = 'token_expiry';
  static const _keyUserId = 'user_id';
  static const _keyUserEmail = 'user_email';
  static const _keyUserName = 'user_name';

  final FlutterSecureStorage _storage;

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _keyAccessToken, value: token);

  Future<String?> getAccessToken() =>
      _storage.read(key: _keyAccessToken);

  Future<void> saveRefreshToken(String? token) =>
      _storage.write(key: _keyRefreshToken, value: token);

  Future<String?> getRefreshToken() =>
      _storage.read(key: _keyRefreshToken);

  Future<void> saveTokenExpiry(DateTime? expiry) async {
    final value = expiry?.millisecondsSinceEpoch.toString();
    await _storage.write(key: _keyTokenExpiry, value: value);
  }

  Future<DateTime?> getTokenExpiry() async {
    final value = await _storage.read(key: _keyTokenExpiry);
    if (value == null) return null;
    final ms = int.tryParse(value);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> saveUser({
    required String id,
    required String email,
    required String name,
  }) async {
    await _storage.write(key: _keyUserId, value: id);
    await _storage.write(key: _keyUserEmail, value: email);
    await _storage.write(key: _keyUserName, value: name);
  }

  Future<Map<String, String?>> getUser() async {
    final id = await _storage.read(key: _keyUserId);
    final email = await _storage.read(key: _keyUserEmail);
    final name = await _storage.read(key: _keyUserName);
    return {'id': id, 'email': email, 'name': name};
  }

  Future<void> clearAll() => _storage.deleteAll();
}

