import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:betebrana_mobile/features/library/domain/entities/book.dart';
import 'package:betebrana_mobile/features/library/domain/entities/rental.dart';
import 'package:betebrana_mobile/features/library/data/rental_repository.dart';
import 'package:betebrana_mobile/core/config/app_config.dart';

class BookDownloadService {
  static const String _storageKeyPrefix = 'book_key_';
  static const String _rentalInfoKeyPrefix = 'rental_info_';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late RentalRepository _rentalRepository;
  
  BookDownloadService() {
    _rentalRepository = RentalRepository();
  }
  
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
    final txtFile = File('$dirPath/book_$bookId.txt');
    return txtFile.existsSync() ? txtFile.path : null;
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
        await deleteBook(bookId);
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
      
      // Use the correct download endpoint WITHOUT authentication
      final downloadUrl = '${AppConfig.baseApiUrl}/books/${book.id}/download-test';
      
      print('Downloading from: $downloadUrl');
      
      final httpClient = HttpClient();
      
      final request = await httpClient.getUrl(Uri.parse(downloadUrl));
      
      // NO authorization headers needed for testing
      
      final response = await request.close();

      if (response.statusCode != 200) {
        print('HTTP Status Code: ${response.statusCode}');
        print('Response headers: ${response.headers}');
        throw Exception('Failed to download book: ${response.statusCode}');
      }

      // Parse JSON response
      final jsonResponse = await response.transform(utf8.decoder).join();
      print('Download response: ${jsonResponse.substring(0, 100)}...');
      
      final parsed = json.decode(jsonResponse);
      
      if (!parsed['success']) {
        throw Exception(parsed['error'] ?? 'Download failed');
      }
      
      final content = parsed['book']['content'];
      
      // Encrypt the text content
      final encrypted = encrypter.encrypt(content, iv: iv);
      
      // Save encrypted text file with IV prepended
      final dirPath = await getDownloadDirectory();
      final file = File('$dirPath/book_${book.id}.enc');
      
      await file.writeAsString(json.encode({
        'iv': iv.base64,
        'content': encrypted.base64,
      }));
      
      // Also save a decrypted TXT file for ReaderPage to read directly
      final txtFile = File('$dirPath/book_${book.id}.txt');
      await txtFile.writeAsString(content, flush: true);
      
      // Store book metadata
      await _storeBookMetadata(book, rentalExpiry);
      
      print('Book downloaded and encrypted successfully!');
      
    } catch (e) {
      print('Download error: $e');
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
      'fileType': 'txt',
    }));
  }

  Future<String?> getDecryptedBookContent(int bookId) async {
    try {
      // Check if rental is still valid
      final rentalInfoKey = '$_rentalInfoKeyPrefix$bookId';
      final rentalInfo = await _secureStorage.read(key: rentalInfoKey);
      
      if (rentalInfo == null) {
        // No rental info, delete the file
        await deleteBook(bookId);
        return null;
      }
      
      final info = json.decode(rentalInfo);
      final expiryDate = DateTime.parse(info['expiry']);
      
      if (expiryDate.isBefore(DateTime.now())) {
        // Rental expired
        await deleteBook(bookId);
        return null;
      }
      
      // First try to read the decrypted TXT file
      final dirPath = await getDownloadDirectory();
      final txtFile = File('$dirPath/book_$bookId.txt');
      
      if (await txtFile.exists()) {
        return await txtFile.readAsString();
      }
      
      // If TXT file doesn't exist, try to decrypt the encrypted file
      final encFile = File('$dirPath/book_$bookId.enc');
      if (!await encFile.exists()) {
        return null;
      }
      
      final encryptedData = json.decode(await encFile.readAsString());
      final iv = encrypt.IV.fromBase64(encryptedData['iv']);
      
      // Get encryption key
      final keyName = '$_storageKeyPrefix$bookId';
      final keyBase64 = await _secureStorage.read(key: keyName);
      
      if (keyBase64 == null) {
        await deleteBook(bookId);
        return null;
      }
      
      final key = encrypt.Key.fromBase64(keyBase64);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      
      // Decrypt
      final decrypted = encrypter.decrypt64(encryptedData['content'], iv: iv);
      
      // Save as TXT file for future use
      await txtFile.writeAsString(decrypted, flush: true);
      
      return decrypted;
    } catch (e) {
      print('Error decrypting book: $e');
      return null;
    }
  }

  Future<void> deleteBook(int bookId) async {
    try {
      // Delete encrypted file
      final dirPath = await getDownloadDirectory();
      final encFile = File('$dirPath/book_$bookId.enc');
      if (await encFile.exists()) {
        await encFile.delete();
      }
      
      // Delete TXT file
      final txtFile = File('$dirPath/book_$bookId.txt');
      if (await txtFile.exists()) {
        await txtFile.delete();
      }
      
      // Delete metadata
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
            await deleteBook(bookId);
            continue;
          }
          
          // Get the TXT file path
          final txtFilePath = '${file.parent.path}/book_${metadata['id']}.txt';
          final txtFile = File(txtFilePath);
          
          // Only add if TXT file exists (readable by ReaderPage)
          if (await txtFile.exists()) {
            books.add(Book(
              id: metadata['id'].toString(),
              title: metadata['title'] ?? '',
              author: metadata['author'] ?? '',
              description: metadata['description'],
              coverImagePath: metadata['coverImagePath'],
              filePath: txtFilePath,
              fileType: metadata['fileType'] ?? 'txt',
              availableCopies: 0,
              totalCopies: 0,
              queueInfo: null,
              userHasRental: true,
              downloadExpiryDate: expiryDate,
              downloadDate: DateTime.parse(metadata['downloadDate']),
              isDownloaded: true, 
              localFilePath: txtFilePath, 
            ));
          }
        } catch (e) {
          print('Error reading metadata: $e');
        }
      }
    }
    
    return books;
  }

  Future<bool> isBookDownloaded(int bookId) async {
    // Check if TXT file exists
    final dirPath = await getDownloadDirectory();
    final txtFile = File('$dirPath/book_$bookId.txt');
    if (!await txtFile.exists()) return false;
    
    // Also check if rental is still valid
    final rentalInfoKey = '$_rentalInfoKeyPrefix$bookId';
    final rentalInfo = await _secureStorage.read(key: rentalInfoKey);
    
    if (rentalInfo == null) {
      await deleteBook(bookId);
      return false;
    }
    
    final info = json.decode(rentalInfo);
    final expiryDate = DateTime.parse(info['expiry']);
    
    if (expiryDate.isBefore(DateTime.now())) {
      await deleteBook(bookId);
      return false;
    }
    
    return true;
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
          await deleteBook(int.parse(book.id));
        }
      }
    }
  }
  
  // Helper method to get book content for ReaderPage
  Future<String> getBookContent(int bookId) async {
    final content = await getDecryptedBookContent(bookId);
    if (content == null) {
      throw Exception('Book content not found or expired');
    }
    return content;
  }
// In BookDownloadService class, add this method:

Future<String> getLocalBookContent(Book book) async {
  try {
    final bookId = int.tryParse(book.id);
    if (bookId == null) {
      throw Exception('Invalid book ID');
    }
    
    // First check if it's downloaded
    final isDownloaded = await isBookDownloaded(bookId);
    if (!isDownloaded) {
      throw Exception('Book not downloaded');
    }
    
    // Get local content
    final content = await getBookContent(bookId);
    return content;
  } catch (e) {
    print('Error getting local book content: $e');
    rethrow;
  }
}
  Future<void> syncWithServerAndCleanup() async {
    try {
      final downloadedBooks = await getDownloadedBooks();
      
      // Get active rentals from server
      final activeRentals = await _rentalRepository.getUserRentals();
      
      for (final book in downloadedBooks) {
        final bookId = int.tryParse(book.id);
        if (bookId == null) continue;
        
        // Check if book is still rented
        final isStillRented = activeRentals.any((rental) => 
            rental.bookId == bookId && rental.isActive);
        
        // If not rented anymore, delete downloaded book
        if (!isStillRented) {
          print('Book $bookId no longer rented, removing download...');
          await deleteBook(bookId);
        }
      }
    } catch (e) {
      print('Error syncing downloads with server: $e');
    }
  }

  Future<void> removeDownloadIfExists(int bookId) async {
    final isDownloaded = await isBookDownloaded(bookId);
    if (isDownloaded) {
      await deleteBook(bookId);
      print('Removed downloaded copy of book $bookId');
    }
  }
}