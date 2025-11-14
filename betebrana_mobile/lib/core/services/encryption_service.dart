import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provides AES-256 encryption/decryption using a device-specific key
/// stored securely with [FlutterSecureStorage].
class EncryptionService {
  EncryptionService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _keyDeviceEncryptionKey = 'device_encryption_key_v1';

  final FlutterSecureStorage _secureStorage;
  final Random _random = Random.secure();

  Future<encrypt.Key> _getOrCreateKey() async {
    final stored = await _secureStorage.read(key: _keyDeviceEncryptionKey);
    if (stored != null && stored.isNotEmpty) {
      final bytes = base64Decode(stored);
      return encrypt.Key(Uint8List.fromList(bytes));
    }

    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    final encoded = base64Encode(bytes);
    await _secureStorage.write(key: _keyDeviceEncryptionKey, value: encoded);
    return encrypt.Key(Uint8List.fromList(bytes));
  }

  /// Encrypts [plain] bytes using AES-256-CBC with a random IV.
  ///
  /// The returned bytes are `[iv(16 bytes)] + [ciphertext]`.
  Future<Uint8List> encryptBytes(Uint8List plain) async {
    final key = await _getOrCreateKey();
    final ivBytes = List<int>.generate(16, (_) => _random.nextInt(256));
    final iv = encrypt.IV(Uint8List.fromList(ivBytes));

    final aes = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );

    final encrypted = aes.encryptBytes(plain, iv: iv);
    final result = Uint8List(iv.bytes.length + encrypted.bytes.length);
    result.setRange(0, iv.bytes.length, iv.bytes);
    result.setRange(iv.bytes.length, result.length, encrypted.bytes);
    return result;
  }

  /// Decrypts bytes produced by [encryptBytes].
  Future<Uint8List> decryptBytes(Uint8List data) async {
    if (data.length < 16) {
      throw ArgumentError('Encrypted data is too short');
    }

    final key = await _getOrCreateKey();
    final ivBytes = data.sublist(0, 16);
    final cipherBytes = data.sublist(16);

    final iv = encrypt.IV(ivBytes);
    final aes = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
    );

    final decrypted = aes.decryptBytes(encrypt.Encrypted(cipherBytes), iv: iv);
    return Uint8List.fromList(decrypted);
  }
}

