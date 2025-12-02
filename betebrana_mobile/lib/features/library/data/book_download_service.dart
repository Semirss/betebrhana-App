import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:betebrana_mobile/features/library/domain/entities/book.dart';
import 'package:betebrana_mobile/features/library/domain/entities/rental.dart';

// Simple app configuration holder; replace the URL with your real API base URL
class AppConfig {
  static const String apiBaseUrl = 'https://api.example.com';
}

class BookDownloadService {
  static const String _storageKeyPrefix = 'book_key_';
  static const String _rentalInfoKeyPrefix = 'rental_info_';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  Future<String> getDownloadDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${directory.path}/downloaded_books');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir.path;
  }

  Future<String?> getBookFilePath(int bookId) async {
    final dirPath = await getDownloadDirectory();
    final file = File('$dirPath/book_$bookId.enc');
    return file.existsSync() ? file.path : null;
  }

  Future<encrypt.Key> _generateOrGetKey(int bookId, DateTime rentalExpiry) async {
    final keyName = '$_storageKeyPrefix$bookId';
    
    // Check if key exists and is valid
    final existingKey = await _secureStorage.read(key: keyName);
    if (existingKey != null) {
      // Check if rental info matches
      final rentalInfoKey = '$_rentalInfoKeyPrefix$bookId';
      final rentalInfo = await _secureStorage.read(key: rentalInfoKey);
      
      if (rentalInfo != null) {
        final info = json.decode(rentalInfo);
        final expiryDate = DateTime.parse(info['expiry']);
        
        // If rental hasn't expired, return existing key
        if (expiryDate.isAfter(DateTime.now())) {
          return encrypt.Key.fromBase64(existingKey);
        }
        // Rental expired, delete old key and file
        await _deleteBook(bookId);
      }
    }
    
    // Generate new key
    final key = encrypt.Key.fromSecureRandom(32); // AES-256 requires 32 bytes
    await _secureStorage.write(
      key: keyName,
      value: key.base64,
    );
    
    // Store rental info
    await _secureStorage.write(
      key: '$_rentalInfoKeyPrefix$bookId',
      value: json.encode({
        'expiry': rentalExpiry.toIso8601String(),
        'created': DateTime.now().toIso8601String(),
      }),
    );
    
    return key;
  }

  Future<void> downloadAndEncryptBook(Book book, DateTime rentalExpiry) async {
    try {
      // Generate encryption key tied to rental period
      final key = await _generateOrGetKey(int.parse(book.id), rentalExpiry);
      
      // Create IV (Initialization Vector)
      final iv = encrypt.IV.fromSecureRandom(16);
      
      // Setup encryptor
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      // Download book file
      final response = await HttpClient().getUrl(
        Uri.parse('${AppConfig.apiBaseUrl}/books/${book.id}/download'),
      );
      
      final downloadResponse = await response.close();
      final bytes = await consolidateHttpClientResponseBytes(downloadResponse);
      
      // Encrypt the book content
      final encryptedBytes = encrypter.encryptBytes(bytes, iv: iv).bytes;
      
      // Save encrypted file with IV prepended
      final dirPath = await getDownloadDirectory();
      final file = File('$dirPath/book_${book.id}.enc');
      
      // Write IV (16 bytes) + encrypted content
      await file.writeAsBytes([...iv.bytes, ...encryptedBytes]);
      
      // Store book metadata
      await _storeBookMetadata(book, rentalExpiry);
      
    } catch (e) {
      throw Exception('Failed to download book: $e');
    }
  }

  Future<void> _storeBookMetadata(Book book, DateTime rentalExpiry) async {
    final dirPath = await getDownloadDirectory();
    final metadataFile = File('$dirPath/book_${book.id}_metadata.json');
    
    await metadataFile.writeAsString(json.encode({
      'id': book.id,
      'title': book.title,
      'author': book.author,
      'coverImagePath': book.coverImagePath,
      'downloadDate': DateTime.now().toIso8601String(),
      'expiryDate': rentalExpiry.toIso8601String(),
      'description': book.description,
    }));
  }

  Future<Uint8List?> getDecryptedBookContent(int bookId) async {
    try {
      // Check if rental is still valid
      final rentalInfoKey = '$_rentalInfoKeyPrefix$bookId';
      final rentalInfo = await _secureStorage.read(key: rentalInfoKey);
      
      if (rentalInfo == null) {
        // No rental info, delete the file
        await _deleteBook(bookId);
        return null;
      }
      
      final info = json.decode(rentalInfo);
      final expiryDate = DateTime.parse(info['expiry']);
      
      if (expiryDate.isBefore(DateTime.now())) {
        // Rental expired
        await _deleteBook(bookId);
        return null;
      }
      
      // Get encryption key
      final keyName = '$_storageKeyPrefix$bookId';
      final keyBase64 = await _secureStorage.read(key: keyName);
      
      if (keyBase64 == null) {
        await _deleteBook(bookId);
        return null;
      }
      
      final key = encrypt.Key.fromBase64(keyBase64);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      // Read encrypted file
      final filePath = await getBookFilePath(bookId);
      if (filePath == null) return null;
      
      final file = File(filePath);
      final encryptedBytes = await file.readAsBytes();
      
      // First 16 bytes are IV
      final iv = encrypt.IV(encryptedBytes.sublist(0, 16));
      final contentBytes = encryptedBytes.sublist(16);
      
      // Decrypt
      final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(contentBytes),
        iv: iv,
      );
      
      return Uint8List.fromList(decrypted);
    } catch (e) {
      print('Error decrypting book: $e');
      return null;
    }
  }

  Future<void> _deleteBook(int bookId) async {
    try {
      // Delete encrypted file
      final filePath = await getBookFilePath(bookId);
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      // Delete metadata
      final dirPath = await getDownloadDirectory();
      final metadataFile = File('$dirPath/book_${bookId}_metadata.json');
      if (await metadataFile.exists()) {
        await metadataFile.delete();
      }
      
      // Delete encryption key
      await _secureStorage.delete(key: '$_storageKeyPrefix$bookId');
      
      // Delete rental info
      await _secureStorage.delete(key: '$_rentalInfoKeyPrefix$bookId');
    } catch (e) {
      print('Error deleting book: $e');
    }
  }

  Future<List<Book>> getDownloadedBooks() async {
    final List<Book> books = [];
    final dirPath = await getDownloadDirectory();
    final directory = Directory(dirPath);
    
    if (!await directory.exists()) return books;
    
    final files = await directory.list().toList();
    
    for (final file in files) {
      if (file.path.endsWith('_metadata.json')) {
        try {
          final metadataFile = File(file.path);
          final content = await metadataFile.readAsString();
          final metadata = json.decode(content);
          
          // Check if still valid
          final expiryDate = DateTime.parse(metadata['expiryDate']);
          if (expiryDate.isBefore(DateTime.now())) {
            // Expired, delete
            final bookId = int.parse(metadata['id'].toString());
            await _deleteBook(bookId);
            continue;
          }
          
          books.add(Book(
            id: metadata['id'].toString(),
            title: metadata['title'] ?? '',
            author: metadata['author'] ?? '',
            description: metadata['description'],
            coverImagePath: metadata['coverImagePath'],
            filePath: await getBookFilePath(int.parse(metadata['id'].toString())),
            // isAvailable: true,
            availableCopies: 0,
            totalCopies: 0,
            queueInfo: null,
            userHasRental: true,
          ));
        } catch (e) {
          print('Error reading metadata: $e');
        }
      }
    }
    
    return books;
  }

  Future<void> cleanupExpiredBooks() async {
    final downloadedBooks = await getDownloadedBooks();
    final now = DateTime.now();
    
    for (final book in downloadedBooks) {
      final rentalInfoKey = '$_rentalInfoKeyPrefix${book.id}';
      final rentalInfo = await _secureStorage.read(key: rentalInfoKey);
      
      if (rentalInfo != null) {
        final info = json.decode(rentalInfo);
        final expiryDate = DateTime.parse(info['expiry']);
        
        if (expiryDate.isBefore(now)) {
          await _deleteBook(int.parse(book.id));
        }
      }
    }
  }
}