// encryption_service.dart (FIXED VERSION - Singleton with proper persistence)
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Provides AES-256 encryption/decryption using a device-specific key
/// stored securely with [FlutterSecureStorage].
class EncryptionService {
  // Singleton pattern to ensure only one instance
  static final EncryptionService _instance = EncryptionService._internal();
  
  factory EncryptionService() {
    return _instance;
  }
  
  EncryptionService._internal({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _keyDeviceEncryptionKey = 'device_encryption_key_v1';
  
  final FlutterSecureStorage _secureStorage;
  final Random _random = Random.secure();
  
  // Cache the key in memory
  encrypt.Key? _cachedKey;

  Future<encrypt.Key> _getOrCreateKey() async {
    // Return cached key if available
    if (_cachedKey != null) {
      print('Using cached encryption key');
      return _cachedKey!;
    }

    try {
      // Try to read from secure storage
      final stored = await _secureStorage.read(key: _keyDeviceEncryptionKey);
      
      if (stored != null && stored.isNotEmpty) {
        print('Found existing encryption key in secure storage');
        try {
          final bytes = base64Decode(stored);
          _cachedKey = encrypt.Key(Uint8List.fromList(bytes));
          print('Successfully loaded encryption key');
          return _cachedKey!;
        } catch (e) {
          print('Error decoding stored key: $e');
          // If key is corrupted, delete it and generate new one
          await _secureStorage.delete(key: _keyDeviceEncryptionKey);
          _cachedKey = null;
        }
      }

      // Generate new key
      print('Generating new encryption key...');
      final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
      final encoded = base64Encode(bytes);
      
      // Save to secure storage
      await _secureStorage.write(key: _keyDeviceEncryptionKey, value: encoded);
      
      _cachedKey = encrypt.Key(Uint8List.fromList(bytes));
      print('New encryption key generated and saved');
      
      return _cachedKey!;
    } catch (e) {
      print('Error in _getOrCreateKey: $e');
      // Fallback: generate in-memory key (won't persist)
      final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
      _cachedKey = encrypt.Key(Uint8List.fromList(bytes));
      print('Using in-memory fallback key');
      return _cachedKey!;
    }
  }

  /// Debug method to check if key exists
  Future<bool> hasStoredKey() async {
    try {
      final stored = await _secureStorage.read(key: _keyDeviceEncryptionKey);
      return stored != null && stored.isNotEmpty;
    } catch (e) {
      print('Error checking stored key: $e');
      return false;
    }
  }

  /// Debug method to get key info
  Future<Map<String, dynamic>> getKeyInfo() async {
    try {
      final stored = await _secureStorage.read(key: _keyDeviceEncryptionKey);
      return {
        'hasKey': stored != null,
        'keyLength': stored?.length ?? 0,
        'keyExists': await hasStoredKey(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Encrypts [plain] bytes using AES-256-CBC with a random IV.
  ///
  /// The returned bytes are `[iv(16 bytes)] + [ciphertext]`.
  Future<Uint8List> encryptBytes(Uint8List plain) async {
    try {
      print('Starting encryption of ${plain.length} bytes');
      
      final key = await _getOrCreateKey();
      print('Got encryption key, length: 32 bytes');
      
      final ivBytes = List<int>.generate(16, (_) => _random.nextInt(256));
      final iv = encrypt.IV(Uint8List.fromList(ivBytes));
      print('Generated IV: ${iv.base64}');

      final aes = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
      );

      print('Encrypting...');
      final encrypted = aes.encryptBytes(plain, iv: iv);
      print('Encryption successful. Ciphertext length: ${encrypted.bytes.length} bytes');
      
      // Combine IV + ciphertext
      final result = Uint8List(iv.bytes.length + encrypted.bytes.length);
      result.setRange(0, iv.bytes.length, iv.bytes);
      result.setRange(iv.bytes.length, result.length, encrypted.bytes);
      
      print('Total encrypted data length: ${result.length} bytes');
      print('IV (first 16 bytes): ${result.sublist(0, 16).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      
      return result;
    } catch (e) {
      print('Encryption error: $e');
      rethrow;
    }
  }

  /// Decrypts bytes produced by [encryptBytes].
  Future<Uint8List> decryptBytes(Uint8List data) async {
    try {
      print('Starting decryption of ${data.length} bytes');
      
      if (data.length < 16) {
        throw ArgumentError('Encrypted data is too short (${data.length} bytes, need at least 16)');
      }

      final key = await _getOrCreateKey();
      print('Got decryption key');
      
      final ivBytes = data.sublist(0, 16);
      final cipherBytes = data.sublist(16);
      
      print('IV length: ${ivBytes.length}, Ciphertext length: ${cipherBytes.length}');
      print('IV (hex): ${ivBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

      final iv = encrypt.IV(ivBytes);
      final aes = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: 'PKCS7'),
      );

      print('Decrypting...');
      final decrypted = aes.decryptBytes(encrypt.Encrypted(cipherBytes), iv: iv);
      print('Decryption successful. Decrypted length: ${decrypted.length} bytes');
      
      return Uint8List.fromList(decrypted);
    } catch (e) {
      print('Decryption error: $e');
      print('Data length: ${data.length}');
      print('First 32 bytes (hex): ${data.take(32).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      rethrow;
    }
  }

  /// Clear the cached key (for testing)
  Future<void> clearCache() async {
    _cachedKey = null;
    print('Cleared encryption key cache');
  }

  /// Delete the stored key (for debugging)
  Future<void> deleteStoredKey() async {
    await _secureStorage.delete(key: _keyDeviceEncryptionKey);
    _cachedKey = null;
    print('Deleted stored encryption key');
  }
}