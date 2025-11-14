import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:betebrana_mobile/core/services/encryption_service.dart';

class OfflineBookEntry {
  OfflineBookEntry({
    required this.bookId,
    required this.path,
    required this.expiresAt,
    required this.fileType,
  });

  final String bookId;
  final String path;
  final DateTime expiresAt;
  final String fileType;

  bool get isExpired => expiresAt.isBefore(DateTime.now().toUtc());

  Map<String, dynamic> toJson() {
    return {
      'bookId': bookId,
      'path': path,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      'fileType': fileType,
    };
  }

  factory OfflineBookEntry.fromJson(Map<String, dynamic> json) {
    final expiresRaw = json['expiresAt'] as String?;
    final expires = expiresRaw != null ? DateTime.tryParse(expiresRaw) : null;
    return OfflineBookEntry(
      bookId: json['bookId'] as String,
      path: json['path'] as String,
      expiresAt: (expires ?? DateTime.fromMillisecondsSinceEpoch(0)).toUtc(),
      fileType: (json['fileType'] as String?) ?? 'txt',
    );
  }
}

/// Manages encrypted offline storage for book files.
class OfflineBookService {
  OfflineBookService({EncryptionService? encryptionService})
      : _encryptionService = encryptionService ?? EncryptionService();

  static const _prefsKeyOfflineBooks = 'offline_books_v1';

  final EncryptionService _encryptionService;

  Future<Directory> _getBooksDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/offline_books');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<List<OfflineBookEntry>> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKeyOfflineBooks);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];

    final result = <OfflineBookEntry>[];
    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        result.add(OfflineBookEntry.fromJson(item));
      }
    }
    return result;
  }

  Future<void> _saveEntries(List<OfflineBookEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final list = entries.map((e) => e.toJson()).toList();
    await prefs.setString(_prefsKeyOfflineBooks, jsonEncode(list));
  }

  Future<OfflineBookEntry?> getEntryForBook(String bookId) async {
    final entries = await _loadEntries();
    OfflineBookEntry? found;
    for (final e in entries) {
      if (e.bookId == bookId) {
        found = e;
        break;
      }
    }
    if (found == null) return null;

    final file = File(found.path);
    if (found.isExpired || !await file.exists()) {
      await deleteOfflineCopy(bookId);
      return null;
    }
    return found;
  }

  Future<bool> hasValidOfflineCopy(String bookId) async {
    final entry = await getEntryForBook(bookId);
    return entry != null;
  }

  Future<void> deleteOfflineCopy(String bookId) async {
    final entries = await _loadEntries();
    final remaining = <OfflineBookEntry>[];
    for (final e in entries) {
      if (e.bookId == bookId) {
        final file = File(e.path);
        if (file.existsSync()) {
          try {
            file.deleteSync();
          } catch (_) {
            // ignore deletion error
          }
        }
      } else {
        remaining.add(e);
      }
    }
    await _saveEntries(remaining);
  }

  /// Saves TXT content for [bookId] encrypted on disk with [expiresAt].
  Future<OfflineBookEntry> saveTxtContent({
    required String bookId,
    required String content,
    required String fileType,
    required DateTime expiresAt,
  }) async {
    final dir = await _getBooksDir();
    final sanitizedId = bookId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final file = File('${dir.path}/book_$sanitizedId.txt.enc');

    final plainBytes = Uint8List.fromList(utf8.encode(content));
    final encrypted = await _encryptionService.encryptBytes(plainBytes);
    await file.writeAsBytes(encrypted, flush: true);

    final entry = OfflineBookEntry(
      bookId: bookId,
      path: file.path,
      expiresAt: expiresAt.toUtc(),
      fileType: fileType,
    );

    final entries = await _loadEntries();
    final withoutCurrent =
        entries.where((e) => e.bookId != bookId).toList(growable: true);
    withoutCurrent.add(entry);
    await _saveEntries(withoutCurrent);

    return entry;
  }

  /// Reads TXT content for [bookId] from encrypted offline storage.
  /// Throws if no valid offline copy exists.
  Future<String> readTxtContent(String bookId) async {
    final entry = await getEntryForBook(bookId);
    if (entry == null) {
      throw StateError('No valid offline copy for this book');
    }

    final file = File(entry.path);
    final encrypted = await file.readAsBytes();
    final decrypted = await _encryptionService.decryptBytes(encrypted);
    return utf8.decode(decrypted);
  }
}

