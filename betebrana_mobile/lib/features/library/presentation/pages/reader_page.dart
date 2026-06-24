import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:betebrana_mobile/features/library/data/book_download_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:betebrana_mobile/core/config/app_config.dart';
import 'package:betebrana_mobile/core/network/dio_client.dart';
import 'package:betebrana_mobile/features/library/data/offline_book_service.dart';
import 'package:betebrana_mobile/features/library/domain/entities/book.dart';
import 'package:betebrana_mobile/core/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:epub_view/epub_view.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../../core/utils/tutorial_helper.dart';
import '../widgets/reader_header.dart';
import '../widgets/reader_bottom_controls.dart';
import '../widgets/display_settings_sheet.dart';
import '../widgets/chapter_list_sheet.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage(
      {super.key, required this.book, this.rentalDueDate, this.sponsorId});

  final Book book;
  final DateTime? rentalDueDate;
  final int? sponsorId;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage>
    with SingleTickerProviderStateMixin {
  late Future<String> _txtFuture;
  late OfflineBookService _offlineBookService;
  bool _hasOfflineCopy = false;
  bool _downloadInProgress = false;
  DateTime? _offlineExpiresAt;

  String? _pdfPath;
  EpubController? _epubController;
  String? _tempDecryptedFilePath;

  // Settings state
  ReaderSettings _settings = const ReaderSettings();
  bool _isBookmarked = false;
  bool _isAutoScrolling = false;
  bool _isOrientationLandscape = false;
  bool _isLockEnabled = false;
  bool _isSearching = false;
  bool _showUI = true;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  int _totalPages = 1;
  double _currentProgress = 0.0;
  double? _initialProgress;

  // Global Keys for Tutorial
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _lockKey = GlobalKey();
  final GlobalKey _pageInfoKey = GlobalKey();
  final GlobalKey _chapterKey = GlobalKey();
  final GlobalKey _bookmarkKey = GlobalKey();
  final GlobalKey _autoScrollKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();

  // Ad State
  Map<String, dynamic>?
      _sharedAd; // Single ad used for both banner and interstitial
  bool _showInterstitial = false;
  bool _isLoadingAds = true;
  int _adCountdown = 5; // 5-second countdown before close button appears
  Timer? _adCountdownTimer;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadBookmark();

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final max = _scrollController.position.maxScrollExtent;
        if (max > 0) {
          _currentProgress = _scrollController.offset / max;
        }
        if (_showUI) {
          setState(() {
            _showUI = false;
            if (_isSearching) _isSearching = false;
          });
        }
      }
    });
    _offlineBookService = OfflineBookService();
    _initTxtFuture();
    _refreshOfflineState();
    _fetchAds();
    // Hide status bar for immersive reading
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowTutorial();
    });
  }

  Future<void> _checkAndShowTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('is_first_launch_reader_tutorial') ?? false;
    if (!hasShown) {
      _showTutorial();
    }
  }

  void _showTutorial() {
    final targets = [
      TutorialHelper.createTarget(
        identify: "chapter",
        keyTarget: _chapterKey,
        title: "Chapters",
        description: "Quickly navigate through the book's chapters.",
        contentAlign: ContentAlign.top,
      ),
      TutorialHelper.createTarget(
        identify: "bookmark",
        keyTarget: _bookmarkKey,
        title: "Bookmarks",
        description: "Save your spot so you don't lose your place.",
        contentAlign: ContentAlign.top,
      ),
      TutorialHelper.createTarget(
        identify: "autoScroll",
        keyTarget: _autoScrollKey,
        title: "Auto-Scroll",
        description:
            "Let the app scroll for you. Perfect for hands-free reading.",
        contentAlign: ContentAlign.top,
      ),
      TutorialHelper.createTarget(
        identify: "settings",
        keyTarget: _settingsKey,
        title: "Display Settings",
        description:
            "Change font, size, theme, and more for the perfect reading experience.",
        contentAlign: ContentAlign.top,
        alignSkip: Alignment.topLeft,
      ),
      TutorialHelper.createTarget(
        identify: "search",
        keyTarget: _searchKey,
        title: "Search",
        description: "Find specific words or phrases in the text.",
        contentAlign: ContentAlign.bottom,
      ),
      TutorialHelper.createTarget(
        identify: "lock",
        keyTarget: _lockKey,
        title: "Lock Settings",
        description:
            "Lock your current display settings to prevent accidental changes.",
        contentAlign: ContentAlign.bottom,
      ),
      TutorialHelper.createTarget(
        identify: "pageInfo",
        keyTarget: _pageInfoKey,
        title: "Page Info",
        description: "See your current progress and page number here.",
        contentAlign: ContentAlign.bottom,
      ),
    ];

    TutorialHelper.showTutorial(
      context: context,
      targets: targets,
      onFinish: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_first_launch_reader_tutorial', true);
      },
      onSkip: () {
        SharedPreferences.getInstance().then((prefs) {
          prefs.setBool('is_first_launch_reader_tutorial', true);
        });
        return true;
      },
    );
  }

  Future<void> _fetchAds() async {
    print("Fetching Ads... SponsorId: ${widget.sponsorId}");
    final cacheKey = 'cached_reader_ad_${widget.book.id}';
    try {
      final dio = DioClient.instance.dio;
      final queryParam =
          widget.sponsorId != null ? '?sponsor_id=${widget.sponsorId}' : '';

      // Fetch one section (C = interstitial/fullpage) and reuse the same
      // randomly-chosen ad for both the fullpage overlay AND the bottom banner.
      // This ensures both surfaces always show the same sponsor.
      try {
        final resC = await dio.get('/promos/section/C$queryParam');
        print("Ads C Response: ${resC.data}");
        if (resC.data is List && resC.data.isNotEmpty) {
          final ads = resC.data as List;
          final pickedAd =
              ads[math.Random().nextInt(ads.length)] as Map<String, dynamic>;

          // ── Cache the ad locally for offline use ──
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(cacheKey, jsonEncode(pickedAd));

          if (mounted) {
            setState(() {
              _sharedAd = pickedAd;
              _showInterstitial = true;
              _adCountdown = 5;
            });
            _startAdCountdown();
          }
        }
      } catch (e) {
        print("Network error fetching ads: $e — trying cache");
        // ── Offline fallback: load cached ad ──
        await _loadCachedAd(cacheKey);
      }
    } catch (e) {
      print("Error fetching ads: $e");
      await _loadCachedAd(cacheKey);
    } finally {
      if (mounted) setState(() => _isLoadingAds = false);
    }
  }

  Future<void> _loadCachedAd(String cacheKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(cacheKey);
      if (raw != null && raw.isNotEmpty) {
        final ad = jsonDecode(raw) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _sharedAd = ad;
            _showInterstitial = true;
            _adCountdown = 5;
          });
          _startAdCountdown();
          print('Loaded cached ad for offline use');
        }
      }
    } catch (e) {
      print('Could not load cached ad: $e');
    }
  }

  void _startAdCountdown() {
    _adCountdownTimer?.cancel();
    _adCountdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_adCountdown > 0) {
          _adCountdown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    final baseUrl = AppConfig.baseApiUrl.replaceAll('/api', '');
    return "$baseUrl$path";
  }

  Widget _buildBannerAd() {
    if (_sharedAd == null) return const SizedBox.shrink();
    final ad = _sharedAd!;

    return GestureDetector(
      onTap: () async {
        if (ad['redirect_link'] != null) {
          final url = Uri.parse(ad['redirect_link']);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        color: theme.colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SafeArea(
          // Ensure it doesn't overlap home indicator
          child: Row(
            children: [
              if (ad['logo_path'] != null &&
                  _getImageUrl(ad['logo_path']).isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[300],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: CachedNetworkImage(
                    imageUrl: _getImageUrl(ad['logo_path']),
                    fit: BoxFit.cover,
                  ),
                ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ad['u_text'] != null)
                      Text(ad['u_text'],
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: theme.colorScheme.onSurface)),
                    if (ad['redirect_link'] != null)
                      Text('Tap to visit',
                          style: TextStyle(color: Colors.blue, fontSize: 10)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close,
                    size: 18, color: theme.colorScheme.onSurface),
                onPressed: () => setState(() => _sharedAd = null),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _settings = ReaderSettings(
        theme: ReaderTheme.values[prefs.getInt('reader_theme') ?? 0],
        typeface: prefs.getString('reader_typeface') ?? 'Georgia',
        textSize: prefs.getDouble('reader_text_size') ?? 18.0,
        autoScrollSpeed: prefs.getDouble('reader_auto_scroll_speed') ?? 1.0,
        lineHeight: prefs.getDouble('reader_line_height') ?? 1.6,
        alignment:
            ReaderAlignment.values[prefs.getInt('reader_alignment') ?? 0],
        usePublisherDefaults:
            prefs.getBool('reader_publisher_defaults') ?? false,
      );
    });
  }

  Future<void> _loadBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'book_${widget.book.id}_bookmark_progress';
    if (prefs.containsKey(key)) {
      setState(() {
        _isBookmarked = true;
        _initialProgress = prefs.getDouble(key);
      });
    }
  }

  void _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'book_${widget.book.id}_bookmark_progress';

    if (_isBookmarked) {
      await prefs.remove(key);
      setState(() => _isBookmarked = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Bookmark removed')));
      }
    } else {
      await prefs.setDouble(key, _currentProgress);
      setState(() => _isBookmarked = true);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Bookmark saved!')));
      }
    }
  }

  Future<void> _saveSettings(ReaderSettings newSettings) async {
    setState(() => _settings = newSettings);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reader_theme', newSettings.theme.index);
    await prefs.setString('reader_typeface', newSettings.typeface);
    await prefs.setDouble('reader_text_size', newSettings.textSize);
    await prefs.setDouble(
        'reader_auto_scroll_speed', newSettings.autoScrollSpeed);
    await prefs.setDouble('reader_line_height', newSettings.lineHeight);
    await prefs.setInt('reader_alignment', newSettings.alignment.index);
    await prefs.setBool(
        'reader_publisher_defaults', newSettings.usePublisherDefaults);

    // Auto-scroll speed might have changed
    if (_isAutoScrolling) {
      _startAutoScroll(); // Restart with new speed
    }
  }

  ThemeData get theme {
    switch (_settings.theme) {
      case ReaderTheme.light:
        return AppTheme.light().copyWith(
          scaffoldBackgroundColor: const Color(0xFFFDFDFD),
          textTheme:
              AppTheme.light().textTheme.apply(fontFamily: _settings.typeface),
        );
      case ReaderTheme.dark:
        return AppTheme.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF1A1A1A),
          textTheme:
              AppTheme.dark().textTheme.apply(fontFamily: _settings.typeface),
        );
      case ReaderTheme.sepia:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF5EFE1),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.brown,
            surface: const Color(0xFFF5EFE1),
            onSurface: const Color(0xFF4E342E),
          ),
          textTheme: TextTheme(
            bodyMedium: TextStyle(
                color: const Color(0xFF4E342E), fontFamily: _settings.typeface),
          ),
        );
      case ReaderTheme.oled:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF000000),
          colorScheme: const ColorScheme.dark(
            primary: Colors.grey,
            surface: Color(0xFF000000),
            onSurface: Color(0xFFB0B0B0),
          ),
          textTheme: TextTheme(
            bodyMedium: TextStyle(
                color: const Color(0xFFB0B0B0), fontFamily: _settings.typeface),
          ),
        );
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _adCountdownTimer?.cancel();
    _epubController?.dispose();

    // Reset orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Securely delete temporary file after viewing to maintain offline encryption
    if (_tempDecryptedFilePath != null) {
      try {
        final f = File(_tempDecryptedFilePath!);
        if (f.existsSync()) {
          f.deleteSync();
          print(
              'Securely deleted temporary decrypted file: $_tempDecryptedFilePath');
        }
      } catch (e) {
        print('Error deleting secure temp file: $e');
      }
    }

    // Restore system UI overlays
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  void _initTxtFuture() {
    final type = (widget.book.fileType ?? '').toLowerCase();

    // If book is downloaded and has local file path, read from local encrypted storage
    if (widget.book.isDownloaded == true && widget.book.localFilePath != null) {
      if (type == 'pdf' || type == 'epub') {
        _loadDecryptedBinary(type);
        _txtFuture = Future.value('');
      } else {
        _txtFuture = _loadLocalTxtContent(widget.book);
      }
    } else if (type == 'txt') {
      // Fall back to server loading if not downloaded
      _txtFuture = _loadTxtContent(widget.book);
    } else if (type == 'pdf' || type == 'epub') {
      _downloadBinaryForViewing(type);
      _txtFuture = Future.value('');
    } else {
      _txtFuture = Future.value('');
    }
  }

  Future<void> _loadDecryptedBinary(String type) async {
    final bookId = int.tryParse(widget.book.id);
    if (bookId == null) return;

    final downloadService = BookDownloadService();
    // This securely decrypts it to a temp path
    final tempPath =
        await downloadService.getDecryptedBookFilePath(bookId, type);

    if (tempPath != null && mounted) {
      _tempDecryptedFilePath = tempPath;
      if (type == 'pdf') {
        setState(() => _pdfPath = tempPath);
      } else if (type == 'epub') {
        final bytes = await File(tempPath).readAsBytes();
        setState(() {
          _epubController = EpubController(
            document: EpubDocument.openData(bytes),
          );
        });
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Error decrypting book file. Please try downloading again.')),
      );
    }
  }

  Future<String> _loadLocalTxtContent(Book book) async {
    // For encrypted downloaded books, go straight to BookDownloadService
    // (which handles decryption). Never try readAsString() on an encrypted file.
    final bookId = int.tryParse(book.id);
    if (bookId != null) {
      try {
        final downloadService = BookDownloadService();
        final content = await downloadService.getBookContent(bookId);
        print('Loaded decrypted content, length: ${content.length}');
        return content;
      } catch (e) {
        print('BookDownloadService failed: $e');
      }
    }

    // Fallback: try OfflineBookService (plain-text offline cache)
    try {
      final text = await _offlineBookService.readTxtContent(book.id);
      if (text.isNotEmpty) return text;
    } catch (_) {}

    throw Exception(
      'Could not load book offline. Please connect to the internet and open the book once to refresh.',
    );
  }

  Future<void> _refreshOfflineState() async {
    if (widget.book.isDownloaded == true) return;

    final entry = await _offlineBookService.getEntryForBook(widget.book.id);
    if (!mounted) return;
    setState(() {
      _hasOfflineCopy = entry != null;
      _offlineExpiresAt = entry?.expiresAt;
    });
  }

  Future<String> _loadTxtContent(Book book) async {
    // 1. Try offline cache first
    try {
      final entry = await _offlineBookService.getEntryForBook(book.id);
      if (entry != null) {
        final text = await _offlineBookService.readTxtContent(book.id);
        if (mounted) {
          setState(() {
            _hasOfflineCopy = true;
            _offlineExpiresAt = entry.expiresAt;
          });
        }
        return text;
      }
    } catch (_) {}

    // 2. Fetch via the secure proxy endpoint (auth token is sent automatically)
    try {
      final dio = DioClient.instance.dio;
      final response = await dio.get<String>(
        '/books/${book.id}/read',
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
        ),
      );
      return response.data ?? '';
    } catch (_) {
      throw 'Server busy, please try again.';
    }
  }

  Future<void> _downloadBinaryForViewing(String extension) async {
    try {
      final dio = DioClient.instance.dio;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${widget.book.id}.$extension');
      // Download via secure proxy — auth header is set automatically by DioClient
      await dio.download('/books/${widget.book.id}/read', file.path);

      if (mounted) {
        if (extension == 'pdf') {
          setState(() => _pdfPath = file.path);
        } else if (extension == 'epub') {
          final bytes = await file.readAsBytes();
          setState(() {
            _epubController = EpubController(
              document: EpubDocument.openData(bytes),
            );
          });
        }
      }
    } catch (e) {
      print("Error downloading binary for view: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading book file: $e')),
        );
      }
    }
  }

  // Kept for compatibility with _downloadForOffline
  String? _buildDocumentUrl(String? filePath) {
    if (filePath == null || filePath.isEmpty) return null;
    if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
      return filePath;
    }
    var path = filePath.trim();
    if (path.startsWith('/')) path = path.substring(1);
    if (path.startsWith('documents/'))
      path = path.substring('documents/'.length);
    return '${AppConfig.documentsBaseUrl}/$path';
  }

  Future<void> _downloadForOffline() async {
    setState(() => _downloadInProgress = true);
    try {
      final text = await _txtFuture;
      if (text.isEmpty) throw Exception('Book is empty');

      final expiresAt =
          (widget.rentalDueDate ?? DateTime.now().add(const Duration(days: 21)))
              .toUtc();

      final entry = await _offlineBookService.saveTxtContent(
        bookId: widget.book.id,
        content: text,
        fileType: (widget.book.fileType ?? 'txt').toLowerCase(),
        expiresAt: expiresAt,
      );

      if (!mounted) return;
      setState(() {
        _hasOfflineCopy = true;
        _offlineExpiresAt = entry.expiresAt;
        _downloadInProgress = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book downloaded for offline use.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _downloadInProgress = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download book: $e')),
      );
    }
  }

  void _toggleAutoScroll() {
    setState(() {
      _isAutoScrolling = !_isAutoScrolling;
    });
    if (_isAutoScrolling) {
      _startAutoScroll();
    } else {
      _autoScrollTimer?.cancel();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (!_scrollController.hasClients) return;

    // Small frame-rate ticks keep auto-scroll visually smooth without starting
    // overlapping scroll animations.
    _autoScrollTimer =
        Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!_scrollController.hasClients ||
          !_isAutoScrolling ||
          _isLockEnabled) {
        timer.cancel();
        return;
      }
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final delta =
          _settings.autoScrollSpeed * 0.75; // About the same speed, smoother.

      if (currentScroll < maxScroll) {
        _scrollController.jumpTo(math.min(maxScroll, currentScroll + delta));
      } else {
        setState(() => _isAutoScrolling = false);
        timer.cancel();
      }
    });
  }

  void _toggleOrientation() {
    setState(() {
      _isOrientationLandscape = !_isOrientationLandscape;
      if (_isOrientationLandscape) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
    });
  }

  void _showDisplaySettingsSheet() {
    showDisplaySettingsSheet(
      context,
      currentSettings: _settings,
      onSettingsChanged: _saveSettings,
      isLocked: _isLockEnabled,
    );
  }

  void _showChapterList(String fullText) {
    // Basic regex-based chapter extraction for txt files
    final lines = fullText.split('\n');
    final List<Chapter> chapters = [];
    final RegExp chapterRegex =
        RegExp(r'^(Chapter\s+\d+|ምዕራፍ\s+\d+)', caseSensitive: false);

    int charCount = 0;
    final totalChars = fullText.length;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (chapterRegex.hasMatch(line) && line.length < 50) {
        // Approximate progress
        final progress = totalChars > 0 ? charCount / totalChars : 0.0;
        chapters.add(Chapter(
          title: line,
          index: chapters.length,
          scrollOffset: progress,
        ));
      }
      charCount += lines[i].length + 1; // +1 for newline character
    }

    showChapterListSheet(
      context,
      chapters: chapters,
      onChapterSelected: (chapter) {
        // Jump to progress
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          _scrollController.jumpTo(chapter.scrollOffset * maxScroll);
        }
      },
    );
  }

  void _handleSearch() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    // In a real app we'd highlight or jump to the result.
    // For now we just record it.
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
      if (!_showUI && _isSearching) {
        _isSearching = false; // Hide search when UI hides
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final type = (widget.book.fileType ?? '').toLowerCase();
    final currentTheme = this.theme; // Use the getter
    return Theme(
      data: currentTheme,
      child: DefaultTabController(
        length: type == 'txt' ? 2 : 1,
        initialIndex: type == 'txt' ? 1 : 0,
        child: Scaffold(
          backgroundColor: currentTheme.scaffoldBackgroundColor,
          body: Stack(
            children: [
              // ── Full-screen reading area (always fills entire body) ──
              Positioned.fill(
                child: Stack(
                  children: [
                    type == 'txt'
                        ? FutureBuilder<String>(
                            future: _txtFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (snapshot.hasError) {
                                String msg = snapshot.error.toString();
                                if (msg.startsWith('Exception: '))
                                  msg = msg.substring(11);
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.error_outline,
                                            size: 48, color: Color(0xFF5D4037)),
                                        const SizedBox(height: 16),
                                        Text(msg,
                                            textAlign: TextAlign.center,
                                            style:
                                                const TextStyle(fontSize: 16)),
                                        const SizedBox(height: 16),
                                        ElevatedButton(
                                          onPressed: () =>
                                              setState(() => _initTxtFuture()),
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              final text = snapshot.data ?? '';
                              if (text.isEmpty) {
                                return const Center(
                                    child: Text('Book is empty.'));
                              }

                              return TabBarView(
                                physics:
                                    const NeverScrollableScrollPhysics(), // Disable swipe between tabs
                                children: [
                                  _TxtScrollView(
                                    text: text,
                                    settings: _settings,
                                    scrollController: _scrollController,
                                    searchQuery: _searchQuery,
                                    initialProgress: _initialProgress,
                                    onCenterTap: _toggleUI,
                                  ),
                                  _TxtPagedView(
                                    text: text,
                                    settings: _settings,
                                    initialProgress: _initialProgress,
                                    onCenterTap: _toggleUI,
                                    textStyle: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontSize: _settings.textSize,
                                          height: _settings.lineHeight,
                                          color: theme.colorScheme.onSurface,
                                          fontFamily: _settings.typeface,
                                        ) ??
                                        TextStyle(
                                            fontSize: _settings.textSize,
                                            height: _settings.lineHeight,
                                            color: theme.colorScheme.onSurface,
                                            fontFamily: _settings.typeface),
                                    isLockEnabled: _isLockEnabled,
                                    onPageChanged: (page, total) {
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        if (mounted) {
                                          setState(() {
                                            if (_currentPage != page ||
                                                _totalPages != total) {
                                              _currentPage = page;
                                              _totalPages = total;
                                              if (total > 1) {
                                                _currentProgress =
                                                    page / (total - 1);
                                              } else {
                                                _currentProgress = 0.0;
                                              }
                                            }
                                            if (_showUI) {
                                              _showUI = false;
                                              if (_isSearching)
                                                _isSearching = false;
                                            }
                                          });
                                        }
                                      });
                                    },
                                  ),
                                ],
                              );
                            },
                          )
                        : type == 'pdf'
                            ? (_pdfPath != null
                                ? PDFView(
                                    filePath: _pdfPath,
                                    enableSwipe: true,
                                    swipeHorizontal: true,
                                    autoSpacing: true,
                                    pageFling: true,
                                    onError: (error) {
                                      print(error.toString());
                                    },
                                    onPageError: (page, error) {
                                      print('$page: ${error.toString()}');
                                    },
                                  )
                                : const Center(
                                    child: CircularProgressIndicator()))
                            : type == 'epub'
                                ? (_epubController != null
                                    ? EpubView(
                                        controller: _epubController!,
                                      )
                                    : const Center(
                                        child: CircularProgressIndicator()))
                                : const Center(
                                    child: Text('Format not supported')),

                    // Interstitial Ad Overlay
                    if (_showInterstitial && _sharedAd != null)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black,
                          child: Stack(
                            children: [
                              // Background Image
                              Positioned.fill(
                                  child: _sharedAd!['image_path'] != null
                                      ? CachedNetworkImage(
                                          imageUrl: _getImageUrl(
                                              _sharedAd!['image_path']),
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: const Color(0xFF1A1A2E))),
                              // Dark overlay
                              Positioned.fill(
                                child: Container(
                                    color: Colors.black.withOpacity(0.65)),
                              ),
                              // Overlay Content
                              Positioned.fill(
                                child: SafeArea(
                                  child: Center(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_sharedAd!['logo_path'] != null)
                                            Container(
                                              width: 90,
                                              height: 90,
                                              margin: const EdgeInsets.only(
                                                  bottom: 20),
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                boxShadow: const [
                                                  BoxShadow(
                                                      color: Colors.black45,
                                                      blurRadius: 12)
                                                ],
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: CachedNetworkImage(
                                                imageUrl: _getImageUrl(
                                                    _sharedAd!['logo_path']),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          if (_sharedAd!['u_text'] != null)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 28,
                                                      vertical: 12),
                                              child: Text(
                                                _sharedAd!['u_text'],
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    height: 1.4),
                                              ),
                                            ),
                                          const SizedBox(height: 32),
                                          // --- Countdown or action buttons ---
                                          if (_adCountdown > 0) ...[
                                            // Show countdown ring while waiting
                                            SizedBox(
                                              width: 64,
                                              height: 64,
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  CircularProgressIndicator(
                                                    value: _adCountdown / 5.0,
                                                    strokeWidth: 4,
                                                    color: Colors.white,
                                                    backgroundColor:
                                                        Colors.white24,
                                                  ),
                                                  Text(
                                                    '$_adCountdown',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              'Ad — please wait',
                                              style: TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 13),
                                            ),
                                          ] else ...[
                                            // Countdown finished — show action buttons
                                            // PRIMARY: Read Book (highlighted)
                                            ElevatedButton(
                                              onPressed: () => setState(() =>
                                                  _showInterstitial = false),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFFFF7A3B),
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 32,
                                                        vertical: 16),
                                                shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30)),
                                                elevation: 4,
                                                shadowColor:
                                                    const Color(0xFFFF7A3B)
                                                        .withOpacity(0.5),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(Icons.menu_book_rounded,
                                                      size: 20),
                                                  SizedBox(width: 10),
                                                  Text('Read Book',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16)),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            // SECONDARY: Visit Sponsor (subtle)
                                            TextButton(
                                              onPressed: () async {
                                                if (_sharedAd![
                                                        'redirect_link'] !=
                                                    null) {
                                                  final url = Uri.parse(
                                                      _sharedAd![
                                                          'redirect_link']);
                                                  if (await canLaunchUrl(url)) {
                                                    await launchUrl(url,
                                                        mode: LaunchMode
                                                            .externalApplication);
                                                  }
                                                }
                                              },
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(Icons.open_in_new,
                                                      size: 15,
                                                      color: Colors.white54),
                                                  SizedBox(width: 6),
                                                  Text('Visit Sponsor',
                                                      style: TextStyle(
                                                          color: Colors.white54,
                                                          fontSize: 13)),
                                                ],
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 24),
                                        ],
                                      ), // Column
                                    ), // SingleChildScrollView
                                  ), // Center
                                ), // SafeArea
                              ), // Positioned.fill
                            ], // Stack children
                          ),
                        ),
                      ),
                  ],
                ), // end inner Stack
              ), // end Positioned.fill

              // ── Top Header Overlay: slides in/out from top ──
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: !_showUI,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                    offset: _showUI ? Offset.zero : const Offset(0, -1),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      opacity: _showUI ? 1.0 : 0.0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ReaderHeader(
                            title: widget.book.title.isEmpty
                                ? 'Reader'
                                : widget.book.title,
                            pageInfo: 'Page ${_currentPage + 1}',
                            isSearching: _isSearching,
                            isLockEnabled: _isLockEnabled,
                            searchController: _searchController,
                            searchFocusNode: _searchFocusNode,
                            searchKey: _searchKey,
                            lockKey: _lockKey,
                            pageInfoKey: _pageInfoKey,
                            onBackPressed: () => Navigator.pop(context),
                            onToggleSearch: () => setState(() {
                              _isSearching = !_isSearching;
                              if (_isSearching) {
                                _searchFocusNode.requestFocus();
                              } else {
                                _searchController.clear();
                                _searchQuery = '';
                              }
                            }),
                            onClearSearch: () {
                              _searchController.clear();
                              _handleSearch();
                            },
                            onSearchSubmitted: (_) => _handleSearch(),
                            onToggleLock: () => setState(
                                () => _isLockEnabled = !_isLockEnabled),
                            onSearchNext: () {},
                          ),
                          if (type == 'txt')
                            Container(
                              color: currentTheme.scaffoldBackgroundColor,
                              child: TabBar(
                                labelColor: const Color(0xFFFF7A3B),
                                unselectedLabelColor: currentTheme
                                    .colorScheme.onSurface
                                    .withOpacity(0.5),
                                indicatorColor: const Color(0xFFFF7A3B),
                                indicatorWeight: 3.0,
                                labelStyle: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                                unselectedLabelStyle: const TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14),
                                tabs: const [
                                  Tab(text: 'Scroll'),
                                  Tab(text: 'Paged'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── Bottom Controls Overlay: slides in/out from bottom ──
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  ignoring: !_showUI,
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                    offset: _showUI ? Offset.zero : const Offset(0, 1),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      opacity: _showUI ? 1.0 : 0.0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FutureBuilder<String>(
                              future:
                                  type == 'txt' ? _txtFuture : Future.value(''),
                              builder: (context, snapshot) {
                                return ReaderBottomControls(
                                  isBookmarked: _isBookmarked,
                                  isAutoScrolling: _isAutoScrolling,
                                  isOrientationLandscape:
                                      _isOrientationLandscape,
                                  onShowChapterList: () {
                                    if (type == 'txt' && snapshot.hasData) {
                                      _showChapterList(snapshot.data!);
                                    } else {
                                      showChapterListSheet(
                                        context,
                                        chapters: [],
                                        onChapterSelected: (_) {},
                                      );
                                    }
                                  },
                                  onToggleBookmark: _toggleBookmark,
                                  onToggleAutoScroll: _toggleAutoScroll,
                                  onToggleOrientation: _toggleOrientation,
                                  onShowDisplaySettings:
                                      _showDisplaySettingsSheet,
                                  chapterKey: _chapterKey,
                                  bookmarkKey: _bookmarkKey,
                                  autoScrollKey: _autoScrollKey,
                                  settingsKey: _settingsKey,
                                );
                              }),
                          if (_sharedAd != null && !_showInterstitial)
                            GestureDetector(
                                onTap: () async {
                                  if (_sharedAd!['redirect_link'] != null) {
                                    final url =
                                        Uri.parse(_sharedAd!['redirect_link']);
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(url,
                                          mode: LaunchMode.externalApplication);
                                    }
                                  }
                                },
                                child: _buildBannerAd()),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ], // end body Stack
          ), // end Stack
        ), // end Scaffold
      ), // end DefaultTabController
    ); // end Theme
  }
}

// -----------------------------------------------------------------------------
// SCROLL VIEW (Standard)
// -----------------------------------------------------------------------------
class _TxtScrollView extends StatefulWidget {
  const _TxtScrollView({
    super.key,
    required this.text,
    required this.settings,
    required this.scrollController,
    required this.searchQuery,
    this.initialProgress,
    this.onCenterTap,
  });

  final String text;
  final ReaderSettings settings;
  final ScrollController scrollController;
  final String searchQuery;
  final double? initialProgress;
  final VoidCallback? onCenterTap;

  @override
  State<_TxtScrollView> createState() => _TxtScrollViewState();
}

class _TxtScrollViewState extends State<_TxtScrollView> {
  bool _hasScrolledToInitial = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToInitial();
    });
  }

  @override
  void didUpdateWidget(covariant _TxtScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.scrollController.hasClients &&
        widget.scrollController.hasClients) {
      _scrollToInitial();
    }
  }

  void _scrollToInitial() {
    if (mounted && widget.initialProgress != null && !_hasScrolledToInitial) {
      if (widget.scrollController.hasClients) {
        final max = widget.scrollController.position.maxScrollExtent;
        if (max > 0) {
          widget.scrollController.jumpTo(max * widget.initialProgress!);
          _hasScrolledToInitial = true;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    TextAlign getTextAlign() {
      switch (widget.settings.alignment) {
        case ReaderAlignment.center:
          return TextAlign.center;
        case ReaderAlignment.justified:
          return TextAlign.justify;
        default:
          return TextAlign.left;
      }
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onCenterTap,
      child: Scrollbar(
        controller: widget.scrollController,
        interactive: true,
        child: SingleChildScrollView(
          controller: widget.scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).padding.bottom + 128,
          ),
          child: Text(
            widget.text,
            textAlign: getTextAlign(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: widget.settings.textSize,
                  height: widget.settings.lineHeight,
                  fontFamily: widget.settings.typeface,
                ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PAGED VIEW (Advanced E-Reader Style)
// -----------------------------------------------------------------------------
class _TxtPagedView extends StatefulWidget {
  const _TxtPagedView({
    required this.text,
    required this.settings,
    required this.textStyle,
    required this.isLockEnabled,
    this.initialProgress,
    this.onPageChanged,
    this.onCenterTap,
  });

  final String text;
  final ReaderSettings settings;
  final TextStyle textStyle;
  final bool isLockEnabled;
  final double? initialProgress;
  final Function(int, int)? onPageChanged;
  final VoidCallback? onCenterTap;

  @override
  State<_TxtPagedView> createState() => _TxtPagedViewState();
}

class _TxtPagedViewState extends State<_TxtPagedView> {
  late PageController _pageController;
  List<String> _pages = [];
  bool _isPaginating = true;
  int _currentPage = 0;
  Size? _lastSize;
  double? _lastTextScale;
  bool _hasSetInitialPage = false;
  int _paginationRun = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant _TxtPagedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Repaginate if text style (scale/font) or content changes
    if (oldWidget.settings.textSize != widget.settings.textSize ||
        oldWidget.settings.lineHeight != widget.settings.lineHeight ||
        oldWidget.settings.typeface != widget.settings.typeface ||
        oldWidget.settings.alignment != widget.settings.alignment ||
        oldWidget.textStyle != widget.textStyle ||
        oldWidget.text != widget.text) {
      _isPaginating = true; // Trigger layout builder to recalculate
    }
  }

  TextAlign _textAlign() {
    switch (widget.settings.alignment) {
      case ReaderAlignment.center:
        return TextAlign.center;
      case ReaderAlignment.justified:
        return TextAlign.justify;
      default:
        return TextAlign.left;
    }
  }

  TextPainter _layoutText(
    String text,
    double pageWidth,
    TextScaler textScaler,
  ) {
    return TextPainter(
      text: TextSpan(text: text, style: widget.textStyle),
      textAlign: _textAlign(),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: pageWidth);
  }

  bool _fitsPage(
    String text,
    double pageWidth,
    double pageHeight,
    TextScaler textScaler,
  ) {
    if (text.isEmpty) return true;
    final painter = _layoutText(text, pageWidth, textScaler);
    return painter.height <= pageHeight;
  }

  int _previousWordBoundary(String text, int start, int offset) {
    for (int i = math.min(offset, text.length) - 1; i > start; i--) {
      if (RegExp(r'\s').hasMatch(text[i])) {
        return i;
      }
    }
    return -1;
  }

  int _findPageEnd({
    required String text,
    required int start,
    required int end,
    required double pageWidth,
    required double pageHeight,
    required TextScaler textScaler,
  }) {
    final remaining = end - start;
    if (remaining <= 0) return end;

    bool fitsOffset(int offset) {
      final candidate = text.substring(start, start + offset).trimRight();
      return _fitsPage(candidate, pageWidth, pageHeight, textScaler);
    }

    int upper = math.min(remaining, 1024);
    while (upper < remaining && fitsOffset(upper)) {
      final nextUpper = math.min(remaining, upper * 2);
      if (nextUpper == upper) break;
      upper = nextUpper;
    }

    int low = 1;
    int high = upper;
    int best = 0;
    while (low <= high) {
      final mid = (low + high) >> 1;
      if (fitsOffset(mid)) {
        best = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    if (best <= 0) {
      return math.min(start + 1, end);
    }

    int splitIndex = start + best;
    if (splitIndex < end) {
      final wordBoundary = _previousWordBoundary(text, start, splitIndex);
      if (wordBoundary > start) {
        final wordCandidate = text.substring(start, wordBoundary).trimRight();
        if (_fitsPage(wordCandidate, pageWidth, pageHeight, textScaler)) {
          splitIndex = wordBoundary;
        }
      }
    }

    while (splitIndex > start + 1 &&
        !_fitsPage(
          text.substring(start, splitIndex).trimRight(),
          pageWidth,
          pageHeight,
          textScaler,
        )) {
      final wordBoundary = _previousWordBoundary(text, start, splitIndex - 1);
      splitIndex = wordBoundary > start ? wordBoundary : splitIndex - 1;
    }

    return math.min(math.max(splitIndex, start + 1), end);
  }

  /// Calculates pages against the same text box used by the render tree.
  Future<void> _paginate(Size size, TextScaler textScaler) async {
    if (size.width <= 0 || size.height <= 0) return;

    final run = ++_paginationRun;
    final textScale =
        textScaler.scale(widget.textStyle.fontSize ?? widget.settings.textSize);

    // If size hasn't changed materially, don't re-calculate
    if (_lastSize != null &&
        (size.width - _lastSize!.width).abs() < 1 &&
        (size.height - _lastSize!.height).abs() < 1 &&
        _lastTextScale == textScale &&
        !_isPaginating) {
      return;
    }

    _lastSize = size;
    _lastTextScale = textScale;

    // Defer to next frame to allow UI to show loading state
    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted || run != _paginationRun) return;

    final pages = <String>[];
    final text = widget.text;
    // Keep a small safety margin because RenderParagraph can round line boxes
    // differently on some devices. The rendered text area remains full-size.
    final double pageHeight = math.max(1.0, size.height - 2.0);
    final double pageWidth = size.width;
    int start = 0;
    final int end = text.length;

    while (start < end) {
      final splitIndex = _findPageEnd(
        text: text,
        start: start,
        end: end,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        textScaler: textScaler,
      );

      pages.add(text.substring(start, splitIndex).trimRight());
      start = splitIndex;

      // Skip leading whitespace at the start of the next page
      while (start < end && RegExp(r'\s').hasMatch(text[start])) {
        start++;
      }
    }

    if (mounted && run == _paginationRun) {
      setState(() {
        _pages = pages;
        _isPaginating = false;

        if (widget.initialProgress != null &&
            !_hasSetInitialPage &&
            _pages.isNotEmpty) {
          _currentPage =
              (widget.initialProgress! * (_pages.length - 1)).round();
          if (_currentPage >= _pages.length) _currentPage = _pages.length - 1;
          if (_currentPage < 0) _currentPage = 0;
          _hasSetInitialPage = true;
        } else if (_currentPage >= _pages.length) {
          _currentPage = 0;
        }
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          if (!_pageController.position.isScrollingNotifier.value &&
              _pageController.page?.round() != _currentPage) {
            _pageController.jumpToPage(_currentPage);
          }
        }
      });
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // We use LayoutBuilder to get the EXACT size available for the text
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        final textScale = textScaler
            .scale(widget.textStyle.fontSize ?? widget.settings.textSize);
        // Margins chosen to ensure text always clears the overlaid header
        // and bottom-controls bars, giving a premium e-reader feel at any
        // font size. Since bars are Positioned overlays (not in the layout
        // flow), constraints.maxHeight is stable — no repagination on bar
        // show/hide.
        const double horizontalMargin = 24.0;
        const double topMargin = 40.0; // clears header overlay (~36 dp)
        const double bottomMargin = 50.0; // clears bottom-controls overlay
        const double footerHeight = 32.0; // page-counter line

        // The textAreaSize must exactly match what the Text widget renders.
        final Size textAreaSize = Size(
          math.max(1.0, constraints.maxWidth - (horizontalMargin * 2)),
          math.max(
            1.0,
            constraints.maxHeight - topMargin - bottomMargin - footerHeight,
          ),
        );

        // Paginate when explicitly flagged (text/settings changed) or on first
        // run. Ignore height changes — they are stable with the Stack layout.
        if (_isPaginating ||
            _lastSize == null ||
            (textAreaSize.width - (_lastSize?.width ?? 0)).abs() > 1 ||
            (textAreaSize.height - (_lastSize?.height ?? 0)).abs() > 1 ||
            _lastTextScale != textScale) {
          _paginate(textAreaSize, textScaler);
        }

        if (_isPaginating) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Formatting book...'),
              ],
            ),
          );
        }

        return Stack(
          children: [
            GestureDetector(
              onTapUp: (details) {
                final width = MediaQuery.of(context).size.width;
                if (details.localPosition.dx > width * 0.66) {
                  _nextPage();
                } else if (details.localPosition.dx < width * 0.33) {
                  _previousPage();
                } else {
                  widget.onCenterTap?.call();
                }
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  widget.onPageChanged?.call(index, _pages.length);
                },
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.only(
                      left: horizontalMargin,
                      right: horizontalMargin,
                      top: topMargin,
                      bottom: bottomMargin,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: textAreaSize.height,
                          child: Text(
                            _pages[index],
                            textAlign: _textAlign(),
                            style: widget.textStyle,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                        SizedBox(
                          height: footerHeight,
                          child: Center(
                            child: Text(
                              '${index + 1} / ${_pages.length}',
                              style: widget.textStyle.copyWith(
                                fontSize: 11,
                                color:
                                    widget.textStyle.color?.withOpacity(0.45),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
