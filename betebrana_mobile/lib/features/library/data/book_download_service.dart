// book_download_service.dart (updated)
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:betebrana_mobile/features/library/domain/entities/book.dart';
import 'package:betebrana_mobile/features/library/domain/entities/rental.dart';
import 'package:betebrana_mobile/features/library/data/rental_repository.dart';
import 'package:betebrana_mobile/core/config/app_config.dart';
import 'package:betebrana_mobile/core/services/encryption_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadedBookMetadata {
  DownloadedBookMetadata({
    required this.bookId,
    required this.userId,
    required this.path,
    required this.expiresAt,
    required this.downloadedAt,
    required this.title,
    required this.author,
    required this.coverImagePath,
    required this.description,
  });

  final String bookId;
  final String userId;
  final String path;
  final DateTime expiresAt;
  final DateTime downloadedAt;
  final String title;
  final String author;
  final String? coverImagePath;
  final String? description;

  bool get isExpired => expiresAt.isBefore(DateTime.now().toUtc());

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'userId': userId,
      'path': path,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      'downloadedAt': downloadedAt.toUtc().toIso8601String(),
      'title': title,
      'author': author,
      'coverImagePath': coverImagePath,
      'description': description,
    };
  }

  factory DownloadedBookMetadata.fromJson(Map<String, dynamic> json) {
    return DownloadedBookMetadata(
      bookId: json['bookId'] as String,
      userId: json['userId'] as String,
      path: json['path'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String).toUtc(),
      downloadedAt: DateTime.parse(json['downloadedAt'] as String).toUtc(),
      title: json['title'] as String,
      author: json['author'] as String,
      coverImagePath: json['coverImagePath'] as String?,
      description: json['description'] as String?,
    );
  }
}

class BookDownloadService {
  final EncryptionService _encryptionService = EncryptionService();
  final RentalRepository _rentalRepository;
  
  static const _prefsKeyDownloadedBooks = 'downloaded_books_v2';
  
  BookDownloadService() : _rentalRepository = RentalRepository();

  Future<String?> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('current_user_id');
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  Future<String> _getDownloadsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final downloadsDir = Directory('${directory.path}/encrypted_books');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    return downloadsDir.path;
  }

  Future<List<DownloadedBookMetadata>> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKeyDownloadedBooks);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final result = <DownloadedBookMetadata>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          result.add(DownloadedBookMetadata.fromJson(item));
        }
      }
      return result;
    } catch (e) {
      print('Error loading downloaded books entries: $e');
      return [];
    }
  }

  Future<void> _saveEntries(List<DownloadedBookMetadata> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final list = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_prefsKeyDownloadedBooks, jsonEncode(list));
  }

  Future<void> clearDownloadsForPreviousUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = await _getCurrentUserId();
      
      if (currentUserId == null) return;
      
      // Store the current user ID
      await prefs.setString('last_user_id', currentUserId);
    } catch (e) {
      print('Error in clearDownloadsForPreviousUser: $e');
    }
  }

  Future<String> getDownloadDirectory() async {
    return await _getDownloadsDirectory();
  }

  Future<String?> getBookFilePath(int bookId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return null;

    final metadata = await _getBookMetadata(bookId.toString(), userId);
    if (metadata == null || metadata.isExpired) return null;

    return metadata.path;
  }

  Future<DownloadedBookMetadata?> _getBookMetadata(String bookId, String userId) async {
    final entries = await _loadEntries();
    for (final entry in entries) {
      if (entry.bookId == bookId && entry.userId == userId) {
        // Check if file exists and is not expired
        final file = File(entry.path);
        if (entry.isExpired || !await file.exists()) {
          await _deleteBookEntry(bookId, userId);
          return null;
        }
        return entry;
      }
    }
    return null;
  }

  Future<void> downloadAndEncryptBook(Book book, DateTime rentalExpiry) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('No user logged in');
      }

      // Check if already downloaded and valid
      final existing = await _getBookMetadata(book.id, userId);
      if (existing != null && !existing.isExpired) {
        print('Book already downloaded and still valid');
        return;
      }

      // Download content
      final content = await _downloadBookContent(book.id);
      
      // Encrypt and save
      await _saveEncryptedContent(
        bookId: book.id,
        userId: userId,
        content: content,
        expiresAt: rentalExpiry,
        book: book,
      );

      print('Book downloaded and encrypted successfully!');
    } catch (e) {
      print('Download error: $e');
      throw Exception('Failed to download book: $e');
    }
  }

  Future<String> _downloadBookContent(String bookId) async {
    final downloadUrl = '${AppConfig.baseApiUrl}/books/$bookId/download-test';
    
    final httpClient = HttpClient();
    final request = await httpClient.getUrl(Uri.parse(downloadUrl));
    final response = await request.close();

    if (response.statusCode != 200) {
      throw Exception('Failed to download book: ${response.statusCode}');
    }

    final jsonResponse = await response.transform(utf8.decoder).join();
    final parsed = json.decode(jsonResponse);
    
    if (!parsed['success']) {
      throw Exception(parsed['error'] ?? 'Download failed');
    }
    
    return parsed['book']['content'];
  }

  Future<void> _saveEncryptedContent({
    required String bookId,
    required String userId,
    required String content,
    required DateTime expiresAt,
    required Book book,
  }) async {
    // Get storage directory
    final dirPath = await _getDownloadsDirectory();
    
    // Create filename with user ID to separate per-user files
    final sanitizedBookId = bookId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final filename = 'book_${sanitizedBookId}_$userId.enc';
    final file = File('$dirPath/$filename');

    // Encrypt content
    final plainBytes = Uint8List.fromList(utf8.encode(content));
    final encrypted = await _encryptionService.encryptBytes(plainBytes);
    
    // Save encrypted file
    await file.writeAsBytes(encrypted, flush: true);

    // Create entry
    final entry = DownloadedBookMetadata(
      bookId: bookId,
      userId: userId,
      path: file.path,
      expiresAt: expiresAt.toUtc(),
      downloadedAt: DateTime.now().toUtc(),
      title: book.title,
      author: book.author,
      coverImagePath: book.coverImagePath,
      description: book.description,
    );

    // Save entry to preferences
    final entries = await _loadEntries();
    final withoutCurrent = entries.where((e) => 
      !(e.bookId == bookId && e.userId == userId)).toList();
    withoutCurrent.add(entry);
    await _saveEntries(withoutCurrent);
  }

  Future<String?> getDecryptedBookContent(int bookId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return null;

      final metadata = await _getBookMetadata(bookId.toString(), userId);
      if (metadata == null) return null;

      // Read and decrypt file
      final encrypted = await File(metadata.path).readAsBytes();
      final decrypted = await _encryptionService.decryptBytes(encrypted);
      
      return utf8.decode(decrypted);
    } catch (e) {
      print('Error decrypting book: $e');
      return null;
    }
  }

  Future<void> deleteBook(int bookId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return;
    
    await _deleteBookEntry(bookId.toString(), userId);
  }

  Future<void> _deleteBookEntry(String bookId, String userId) async {
    final entries = await _loadEntries();
    final remaining = <DownloadedBookMetadata>[];
    
    for (final entry in entries) {
      if (entry.bookId == bookId && entry.userId == userId) {
        // Delete encrypted file
        final file = File(entry.path);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (e) {
            print('Error deleting book file: $e');
          }
        }
      } else {
        remaining.add(entry);
      }
    }
    
    await _saveEntries(remaining);
  }

  Future<List<Book>> getDownloadedBooks() async {
    final userId = await _getCurrentUserId();
    if (userId == null) return [];

    final entries = await _loadEntries();
    final userEntries = entries.where((e) => e.userId == userId).toList();
    
    final books = <Book>[];
    
    for (final entry in userEntries) {
      if (entry.isExpired) {
        await _deleteBookEntry(entry.bookId, entry.userId);
        continue;
      }

      books.add(Book(
        id: entry.bookId,
        title: entry.title,
        author: entry.author,
        description: entry.description,
        coverImagePath: entry.coverImagePath,
        filePath: entry.path,
        fileType: 'txt',
        availableCopies: 0,
        totalCopies: 0,
        queueInfo: null,
        userHasRental: true,
        downloadExpiryDate: entry.expiresAt,
        downloadDate: entry.downloadedAt,
        isDownloaded: true,
        localFilePath: entry.path,
      ));
    }

    return books;
  }

  Future<bool> isBookDownloaded(int bookId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) return false;
    
    final metadata = await _getBookMetadata(bookId.toString(), userId);
    return metadata != null;
  }

  Future<void> cleanupExpiredBooks() async {
    final entries = await _loadEntries();
    final now = DateTime.now().toUtc();
    
    for (final entry in entries) {
      if (entry.expiresAt.isBefore(now)) {
        await _deleteBookEntry(entry.bookId, entry.userId);
      }
    }
  }

  Future<String> getBookContent(int bookId) async {
    final content = await getDecryptedBookContent(bookId);
    if (content == null) {
      throw Exception('Book content not found or expired');
    }
    return content;
  }

  Future<String> getLocalBookContent(Book book) async {
    try {
      final bookId = int.tryParse(book.id);
      if (bookId == null) {
        throw Exception('Invalid book ID');
      }
      
      final isDownloaded = await isBookDownloaded(bookId);
      if (!isDownloaded) {
        throw Exception('Book not downloaded');
      }
      
      final content = await getBookContent(bookId);
      return content;
    } catch (e) {
      print('Error getting local book content: $e');
      rethrow;
    }
  }

  Future<void> syncWithServerAndCleanup() async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) return;

      final downloadedBooks = await getDownloadedBooks();
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