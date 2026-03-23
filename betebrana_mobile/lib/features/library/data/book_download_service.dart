// book_download_service.dart (UPDATED VERSION)
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
import 'package:betebrana_mobile/core/network/dio_client.dart';
import 'package:dio/dio.dart';

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
    this.fileType = 'txt',
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
  final String fileType;

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
      'fileType': fileType,
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
      fileType: json['fileType'] as String? ?? 'txt',
    );
  }
}

class BookDownloadService {
  final EncryptionService _encryptionService = EncryptionService();
  final RentalRepository _rentalRepository;
  
  static const _prefsKeyDownloadedBooks = 'downloaded_books_v2';
  static const _prefsKeyCurrentUserId = 'current_user_id';
  static const _prefsKeyLastUserId = 'last_user_id';
  
  BookDownloadService() : _rentalRepository = RentalRepository();

  Future<String?> _getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_prefsKeyCurrentUserId);
      
      if (userId == null) {
        print('No current user ID found in SharedPreferences');
      } else {
        print('Retrieved current user ID: $userId');
      }
      
      return userId;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  Future<void> _setCurrentUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKeyCurrentUserId, userId);
      print('Set current user ID: $userId');
    } catch (e) {
      print('Error setting current user ID: $e');
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKeyDownloadedBooks);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      final result = <DownloadedBookMetadata>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          result.add(DownloadedBookMetadata.fromJson(item));
        }
      }
      
      print('Loaded ${result.length} downloaded book entries');
      return result;
    } catch (e) {
      print('Error loading downloaded books entries: $e');
      return [];
    }
  }

  Future<void> _saveEntries(List<DownloadedBookMetadata> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = entries.map((e) => e.toJson()).toList();
      await prefs.setString(_prefsKeyDownloadedBooks, jsonEncode(list));
      print('Saved ${entries.length} downloaded book entries');
    } catch (e) {
      print('Error saving downloaded books entries: $e');
    }
  }

Future<void> clearDownloadsForPreviousUser() async {
  // Do NOT clear anything when user changes
  print('Downloads persist across user sessions - nothing cleared');
}

Future<void> _clearDownloadsForUser(String userId) async {
  // Do NOT clear anything - keep both files and metadata
  print('Downloads preserved for user $userId - nothing cleared');
}

  Future<String> getDownloadDirectory() async {
    return await _getDownloadsDirectory();
  }

  Future<String?> getBookFilePath(int bookId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      print('No user ID, cannot get book file path');
      return null;
    }

    final metadata = await _getBookMetadata(bookId.toString(), userId);
    if (metadata == null || metadata.isExpired) {
      if (metadata == null) print('No metadata for book $bookId');
      if (metadata?.isExpired == true) print('Book $bookId is expired');
      return null;
    }

    return metadata.path;
  }

  Future<DownloadedBookMetadata?> _getBookMetadata(String bookId, String userId) async {
    try {
      final entries = await _loadEntries();
      
      for (final entry in entries) {
        if (entry.bookId == bookId && entry.userId == userId) {
          // Check if file exists and is not expired
          final file = File(entry.path);
          final fileExists = await file.exists();
          
          print('Found metadata for book $bookId, user $userId: exists=$fileExists, expired=${entry.isExpired}');
          
          if (entry.isExpired || !fileExists) {
            print('Deleting invalid entry for book $bookId, user $userId');
            await _deleteBookEntry(bookId, userId);
            return null;
          }
          
          return entry;
        }
      }
      
      print('No metadata found for book $bookId, user $userId');
      return null;
    } catch (e) {
      print('Error getting book metadata: $e');
      return null;
    }
  }

  Future<void> downloadAndEncryptBook(Book book, DateTime rentalExpiry) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        throw Exception('No user logged in - cannot download book');
      }

      print('Starting download for book ${book.id}, user $userId');

      // Check if already downloaded and valid
      final existing = await _getBookMetadata(book.id, userId);
      if (existing != null && !existing.isExpired) {
        print('Book already downloaded and still valid');
        return;
      }

      // Download content
      final contentBytes = await _downloadBookContent(book.id);
      print('Downloaded content length: ${contentBytes.length} bytes');
      
      // Encrypt and save
      await _saveEncryptedContent(
        bookId: book.id,
        userId: userId,
        contentBytes: contentBytes,
        expiresAt: rentalExpiry,
        book: book,
      );

      print('Book downloaded and encrypted successfully!');
    } catch (e) {
      print('Download error: $e');
      throw Exception('Failed to download book: $e');
    }
  }

  Future<Uint8List> _downloadBookContent(String bookId) async {
    final downloadUrl = '/books/$bookId/read';
    print('Downloading binary from proxy: $downloadUrl');
    
    final dio = DioClient.instance.dio;
    final response = await dio.get<List<int>>(
      downloadUrl,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(minutes: 5),
      ),
    );

    if (response.statusCode != 200 || response.data == null) {
      throw Exception('Failed to download book: ${response.statusCode}');
    }

    final contentBytes = Uint8List.fromList(response.data!);
    print('Download successful, content length: ${contentBytes.length} bytes');
    
    return contentBytes;
  }

  Future<void> _saveEncryptedContent({
    required String bookId,
    required String userId,
    required Uint8List contentBytes,
    required DateTime expiresAt,
    required Book book,
  }) async {
    // Get storage directory
    final dirPath = await _getDownloadsDirectory();
    
    // Create filename with user ID to separate per-user files
    final sanitizedBookId = bookId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final filename = 'book_${sanitizedBookId}_$userId.enc';
    final filePath = '$dirPath/$filename';
    final file = File(filePath);

    print('Encrypting content for book $bookId, saving to: $filePath');

    try {
      // Encrypt content
      print('Plain bytes length: ${contentBytes.length}');
      
      final encrypted = await _encryptionService.encryptBytes(contentBytes);
      print('Encrypted bytes length: ${encrypted.length}');
      
      // Save encrypted file
      await file.writeAsBytes(encrypted, flush: true);
      
      // Verify file was saved
      final savedFile = File(filePath);
      final fileSize = await savedFile.length();
      print('File saved successfully. Size: $fileSize bytes');

      // Create entry
      final entry = DownloadedBookMetadata(
        bookId: bookId,
        userId: userId,
        path: filePath,
        expiresAt: expiresAt.toUtc(),
        downloadedAt: DateTime.now().toUtc(),
        title: book.title,
        author: book.author,
        coverImagePath: book.coverImagePath,
        description: book.description,
        fileType: book.fileType ?? 'txt',
      );

      // Save entry to preferences
      final entries = await _loadEntries();
      final withoutCurrent = entries.where((e) => 
        !(e.bookId == bookId && e.userId == userId)).toList();
      withoutCurrent.add(entry);
      await _saveEntries(withoutCurrent);

      print('Metadata saved for book $bookId');
    } catch (e) {
      print('Error saving encrypted content: $e');
      rethrow;
    }
  }

  Future<String?> getDecryptedBookContent(int bookId) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        print('No user ID, cannot decrypt book');
        return null;
      }

      print('Decrypting book $bookId for user $userId');

      final metadata = await _getBookMetadata(bookId.toString(), userId);
      if (metadata == null) {
        print('No metadata found for book $bookId');
        return null;
      }

      print('Found metadata, reading file: ${metadata.path}');

      // Read encrypted file
      final file = File(metadata.path);
      if (!await file.exists()) {
        print('File does not exist: ${metadata.path}');
        return null;
      }

      final encrypted = await file.readAsBytes();
      print('Read ${encrypted.length} encrypted bytes');

      // Try to decrypt
      try {
        final decrypted = await _encryptionService.decryptBytes(encrypted);
        print('Decryption successful, got ${decrypted.length} decrypted bytes');
        
        try {
          final content = utf8.decode(decrypted);
          print('Decoded to string, length: ${content.length} characters (TXT format)');
          return content;
        } catch (e) {
          print('Failed to decode as UTF-8 string. This is expected for PDF and EPUB binary files.');
          return null; // Caller should use getDecryptedBookFilePath for binary
        }
      } catch (e) {
        print('Error during decryption: $e');
        print('This might be due to:');
        print('1. Corrupted encrypted file');
        print('2. Wrong encryption key (different device/session)');
        print('3. Invalid file format');
        
        // Log the raw bytes for debugging
        final hexPreview = encrypted.take(50).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
        print('First 50 bytes (hex): $hexPreview');
        
        // DO NOT delete the file — the error may be a temporary key mismatch
        // (e.g. during debug hot-restarts). Deleting would permanently destroy
        // the user's downloaded book. Just return null and let the caller show
        // a friendly error message.
        print('Decryption failed — keeping file intact for potential retry.');
        return null;
      }
    } catch (e) {
      print('Error decrypting book: $e');
      return null;
    }
  }

  Future<String?> getDecryptedBookFilePath(int bookId, String fileExtension) async {
    try {
      final userId = await _getCurrentUserId();
      if (userId == null) {
        print('No user ID, cannot decrypt book copy');
        return null;
      }

      final metadata = await _getBookMetadata(bookId.toString(), userId);
      if (metadata == null) return null;

      final file = File(metadata.path);
      if (!await file.exists()) return null;

      final encrypted = await file.readAsBytes();
      
      try {
        final decrypted = await _encryptionService.decryptBytes(encrypted);
        
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempFile = File('${tempDir.path}/temp_book_${bookId}_$timestamp.$fileExtension');
        await tempFile.writeAsBytes(decrypted, flush: true);
        
        print('Created temporary decrypted file at: ${tempFile.path}');
        return tempFile.path;
      } catch (e) {
        print('Error during binary decryption: $e');
        return null;
      }
    } catch (e) {
      print('Error getting decrypted book file path: $e');
      return null;
    }
  }

  Future<void> deleteBook(int bookId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      print('No user ID, cannot delete book');
      return;
    }
    
    print('Deleting book $bookId for user $userId');
    await _deleteBookEntry(bookId.toString(), userId);
  }

  Future<void> _deleteBookEntry(String bookId, String userId) async {
    try {
      final entries = await _loadEntries();
      final remaining = <DownloadedBookMetadata>[];
      bool found = false;
      
      for (final entry in entries) {
        if (entry.bookId == bookId && entry.userId == userId) {
          found = true;
          // Delete encrypted file
          final file = File(entry.path);
          if (await file.exists()) {
            try {
              await file.delete();
              print('Deleted file: ${entry.path}');
            } catch (e) {
              print('Error deleting file: $e');
            }
          }
        } else {
          remaining.add(entry);
        }
      }
      
      if (found) {
        await _saveEntries(remaining);
        print('Deleted metadata for book $bookId, user $userId');
      } else {
        print('No metadata found to delete for book $bookId, user $userId');
      }
    } catch (e) {
      print('Error deleting book entry: $e');
    }
  }

  Future<List<Book>> getDownloadedBooks() async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      print('No user ID, returning empty downloaded books list');
      return [];
    }

    print('Getting downloaded books for user $userId');
    
    final entries = await _loadEntries();
    final userEntries = entries.where((e) => e.userId == userId).toList();
    
    print('Found ${userEntries.length} entries for user $userId');
    
    final books = <Book>[];
    
    for (final entry in userEntries) {
      if (entry.isExpired) {
        print('Book ${entry.bookId} is expired, deleting');
        await _deleteBookEntry(entry.bookId, entry.userId);
        continue;
      }

      // Verify file exists
      final file = File(entry.path);
      if (!await file.exists()) {
        print('File does not exist for book ${entry.bookId}, deleting metadata');
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
        fileType: entry.fileType, // Keep orginal type instead of hardcoding txt
        availableCopies: 0,
        totalCopies: 0,
        queueInfo: null,
        userHasRental: true,
        downloadExpiryDate: entry.expiresAt,
        downloadDate: entry.downloadedAt,
        isDownloaded: true,
        localFilePath: entry.path,
      ));
      
      print('Added book to list: ${entry.title}');
    }

    print('Returning ${books.length} downloaded books');
    return books;
  }

  Future<bool> isBookDownloaded(int bookId) async {
    final userId = await _getCurrentUserId();
    if (userId == null) {
      print('No user ID, book is not downloaded');
      return false;
    }
    
    final metadata = await _getBookMetadata(bookId.toString(), userId);
    final isDownloaded = metadata != null;
    print('Book $bookId is downloaded: $isDownloaded');
    return isDownloaded;
  }

  Future<void> cleanupExpiredBooks() async {
    print('Cleaning up expired books');
    final entries = await _loadEntries();
    final now = DateTime.now().toUtc();
    
    for (final entry in entries) {
      if (entry.expiresAt.isBefore(now)) {
        print('Deleting expired book: ${entry.title}');
        await _deleteBookEntry(entry.bookId, entry.userId);
      }
    }
  }

  Future<String> getBookContent(int bookId) async {
    print('Getting book content for $bookId');
    final content = await getDecryptedBookContent(bookId);
    if (content == null) {
      throw Exception('Book content not found or expired. Please re-download the book.');
    }
    return content;
  }

  Future<String> getLocalBookContent(Book book) async {
    try {
      final bookId = int.tryParse(book.id);
      if (bookId == null) {
        throw Exception('Invalid book ID');
      }
      
      print('Getting local content for book: ${book.title} (ID: $bookId)');
      
      final isDownloaded = await isBookDownloaded(bookId);
      if (!isDownloaded) {
        throw Exception('Book not downloaded. Please download it first.');
      }
      
      final content = await getBookContent(bookId);
      print('Successfully retrieved local content, length: ${content.length}');
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

    print('Syncing downloaded books for user $userId');
    
    final downloadedBooks = await getDownloadedBooks();
    if (downloadedBooks.isEmpty) return;

    final activeRentals = await _rentalRepository.getUserRentals();

    // Safety guard: if the server returned an empty rental list (network issue
    // or first-login race condition), do NOT wipe all downloads. We only clean
    // up when we have confirmed rental data.
    if (activeRentals.isEmpty) {
      print('Rental list is empty — skipping sync cleanup to avoid false removals');
      return;
    }

    for (final book in downloadedBooks) {
      final bookId = int.tryParse(book.id);
      if (bookId == null) continue;

      final isStillRented = activeRentals.any((rental) => 
          rental.bookId == bookId && rental.isActive);

      if (!isStillRented) {
        print('Book $bookId no longer rented, removing download...');
        await deleteBook(bookId);
      }
    }
  } catch (e) {
    print('Error syncing downloads: $e');
  }
}

  Future<void> removeDownloadIfExists(int bookId) async {
    final isDownloaded = await isBookDownloaded(bookId);
    if (isDownloaded) {
      await deleteBook(bookId);
      print('Removed downloaded copy of book $bookId');
    } else {
      print('Book $bookId was not downloaded');
    }
  }

Future<void> updateUserSession(String? userId) async {
  if (userId != null) {
    await _setCurrentUserId(userId);
    print('Updated user session to: $userId');
  } else {
    // Clear current user ID on logout — downloads metadata is preserved
    // so they reappear when the same user logs back in.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKeyCurrentUserId);
    print('Cleared user session (logout) - downloads preserved');
  }
}

  // Debug method to list all encrypted files
  Future<void> debugListEncryptedFiles() async {
    try {
      final dirPath = await _getDownloadsDirectory();
      final directory = Directory(dirPath);
      
      if (!await directory.exists()) {
        print('Directory does not exist: $dirPath');
        return;
      }
      
      final files = await directory.list().toList();
      print('=== ENCRYPTED FILES DIRECTORY ===');
      print('Path: $dirPath');
      print('Files found: ${files.length}');
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          print('File: ${file.path}');
          print('  Size: ${stat.size} bytes');
          print('  Modified: ${stat.modified}');
        }
      }
      print('================================');
    } catch (e) {
      print('Error listing files: $e');
    }
  }
}