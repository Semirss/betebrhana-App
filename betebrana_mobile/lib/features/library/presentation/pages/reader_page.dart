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
  TabController? _txtTabController;
  int _txtTabIndex = 0;

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
  final ValueNotifier<int> _adCountdownNotifier = ValueNotifier<int>(5);
  Timer? _adCountdownTimer;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadBookmark();

    if ((widget.book.fileType ?? '').toLowerCase() == 'txt') {
      _txtTabController = TabController(length: 2, vsync: this);
      _txtTabController!.addListener(_handleTxtTabChanged);
    }

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

  void _handleTxtTabChanged() {
    final controller = _txtTabController;
    if (controller == null || _txtTabIndex == controller.index) return;

    setState(() {
      _txtTabIndex = controller.index;
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
              _adCountdownNotifier.value = 5;
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
            _adCountdownNotifier.value = 5;
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
    _adCountdownNotifier.value = 5;
    _adCountdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }

      final nextValue = _adCountdownNotifier.value - 1;
      if (nextValue <= 0) {
        _adCountdownNotifier.value = 0;
        t.cancel();
      } else {
        _adCountdownNotifier.value = nextValue;
      }
    });
  }

  String _getImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith('http')) return path;
    final baseUrl = AppConfig.baseApiUrl.replaceAll('/api', '');
    return "$baseUrl$path";
  }

  Future<void> _openAdLink(Map<String, dynamic> ad) async {
    final redirectLink = ad['redirect_link'];
    if (redirectLink is! String || redirectLink.isEmpty) return;

    final url = Uri.parse(redirectLink);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Widget _buildBannerAd() {
    if (_sharedAd == null) return const SizedBox.shrink();
    final ad = _sharedAd!;

    return GestureDetector(
      onTap: () => _openAdLink(ad),
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

  Widget _buildInterstitialActions(Map<String, dynamic> ad) {
    return ValueListenableBuilder<int>(
      valueListenable: _adCountdownNotifier,
      builder: (context, countdown, _) {
        if (countdown > 0) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: countdown / 5.0,
                      strokeWidth: 4,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                    ),
                    Text(
                      '$countdown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ad - please wait',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => setState(() => _showInterstitial = false),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF78A090),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
                shadowColor: const Color(0xFF78A090).withOpacity(0.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_rounded, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Read Book',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => _openAdLink(ad),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new, size: 15, color: Colors.white54),
                  SizedBox(width: 6),
                  Text(
                    'Visit Sponsor',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
    final oldSettings = _settings;
    if (oldSettings == newSettings) return;

    final changesReaderDisplay = oldSettings.theme != newSettings.theme ||
        oldSettings.typeface != newSettings.typeface ||
        oldSettings.textSize != newSettings.textSize ||
        oldSettings.lineHeight != newSettings.lineHeight ||
        oldSettings.alignment != newSettings.alignment;

    if (changesReaderDisplay) {
      setState(() => _settings = newSettings);
    } else {
      _settings = newSettings;
    }

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

    if (_isAutoScrolling &&
        oldSettings.autoScrollSpeed != newSettings.autoScrollSpeed) {
      _startAutoScroll();
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
    _txtTabController?.removeListener(_handleTxtTabChanged);
    _txtTabController?.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _adCountdownTimer?.cancel();
    _adCountdownNotifier.dispose();
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
        initialIndex: 0,
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

                              final textStyle =
                                  theme.textTheme.bodyMedium?.copyWith(
                                        fontSize: _settings.textSize,
                                        height: _settings.lineHeight,
                                        color: theme.colorScheme.onSurface,
                                        fontFamily: _settings.typeface,
                                      ) ??
                                      TextStyle(
                                        fontSize: _settings.textSize,
                                        height: _settings.lineHeight,
                                        color: theme.colorScheme.onSurface,
                                        fontFamily: _settings.typeface,
                                      );

                              return TabBarView(
                                controller: _txtTabController,
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
                                  _txtTabIndex == 1
                                      ? _TxtPagedView(
                                          text: text,
                                          settings: _settings,
                                          initialProgress: _initialProgress,
                                          onCenterTap: _toggleUI,
                                          textStyle: textStyle,
                                          isLockEnabled: _isLockEnabled,
                                          onPageChanged: (page, total) {
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                              if (!mounted) return;

                                              setState(() {
                                                final pageChanged =
                                                    _currentPage != page;
                                                if (pageChanged ||
                                                    _totalPages != total) {
                                                  _currentPage = page;
                                                  _totalPages = total;
                                                  _currentProgress = total > 1
                                                      ? page / (total - 1)
                                                      : 0.0;
                                                }
                                                if (pageChanged && _showUI) {
                                                  _showUI = false;
                                                  if (_isSearching) {
                                                    _isSearching = false;
                                                  }
                                                }
                                              });
                                            });
                                          },
                                        )
                                      : const SizedBox.shrink(),
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
                                          _buildInterstitialActions(_sharedAd!),
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
                                controller: _txtTabController,
                                labelColor: const Color(0xFF78A090),
                                unselectedLabelColor: currentTheme
                                    .colorScheme.onSurface
                                    .withOpacity(0.5),
                                indicatorColor: const Color(0xFF78A090),
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
                                onTap: () => _openAdLink(_sharedAd!),
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

class _TextSlice {
  const _TextSlice(this.start, this.end);

  final int start;
  final int end;
}

bool _isWhitespaceCodeUnit(int codeUnit) {
  return codeUnit == 0x09 ||
      codeUnit == 0x0A ||
      codeUnit == 0x0B ||
      codeUnit == 0x0C ||
      codeUnit == 0x0D ||
      codeUnit == 0x20;
}

int _skipLeadingWhitespace(String text, int start) {
  var index = start;
  while (index < text.length && _isWhitespaceCodeUnit(text.codeUnitAt(index))) {
    index++;
  }
  return index;
}

int _findReadableBreak(
  String text,
  int start,
  int preferredEnd, {
  double minBreakFraction = 0.55,
}) {
  final length = text.length;
  if (preferredEnd >= length) return length;

  final safePreferredEnd = preferredEnd.clamp(start + 1, length).toInt();
  final minEnd = math
      .min(
        length,
        start +
            math.max(
                1, ((safePreferredEnd - start) * minBreakFraction).floor()),
      )
      .toInt();

  for (final marker in const [
    '\n\n',
    '\n',
    '. ',
    '? ',
    '! ',
    '; ',
    ', ',
    ' '
  ]) {
    final index = text.lastIndexOf(marker, safePreferredEnd);
    if (index >= minEnd) {
      return math.min(length, index + marker.length).toInt();
    }
  }

  return safePreferredEnd;
}

List<_TextSlice> _buildTextSlices(
  String text,
  int targetChars, {
  double minBreakFraction = 0.55,
}) {
  if (text.trim().isEmpty) return const <_TextSlice>[];

  final slices = <_TextSlice>[];
  final target = targetChars.clamp(320, 6000).toInt();
  var start = _skipLeadingWhitespace(text, 0);

  while (start < text.length) {
    final preferredEnd = math.min(start + target, text.length).toInt();
    var end = _findReadableBreak(
      text,
      start,
      preferredEnd,
      minBreakFraction: minBreakFraction,
    );
    if (end <= start) {
      end = math.min(start + target, text.length).toInt();
    }

    slices.add(_TextSlice(start, end));
    start = _skipLeadingWhitespace(text, end);
  }

  return slices;
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
  static const int _targetChunkChars = 1800;

  late List<_TextSlice> _chunks;
  bool _hasScrolledToInitial = false;

  @override
  void initState() {
    super.initState();
    _chunks = _buildTextSlices(widget.text, _targetChunkChars);
    _scheduleScrollToInitial();
  }

  @override
  void didUpdateWidget(covariant _TxtScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _chunks = _buildTextSlices(widget.text, _targetChunkChars);
      _hasScrolledToInitial = false;
      _scheduleScrollToInitial();
    } else if (oldWidget.initialProgress != widget.initialProgress &&
        widget.initialProgress != null) {
      _hasScrolledToInitial = false;
      _scheduleScrollToInitial();
    }
  }

  void _scheduleScrollToInitial() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToInitial());
  }

  void _scrollToInitial() {
    if (!mounted || widget.initialProgress == null || _hasScrolledToInitial) {
      return;
    }
    if (widget.scrollController.hasClients) {
      final max = widget.scrollController.position.maxScrollExtent;
      if (max > 0) {
        widget.scrollController.jumpTo(max * widget.initialProgress!);
        _hasScrolledToInitial = true;
      }
    } else {
      _scheduleScrollToInitial();
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

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: widget.settings.textSize,
          height: widget.settings.lineHeight,
          fontFamily: widget.settings.typeface,
        );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: widget.onCenterTap,
      child: Scrollbar(
        controller: widget.scrollController,
        interactive: true,
        child: ListView.builder(
          controller: widget.scrollController,
          physics: const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).padding.bottom + 128,
          ),
          cacheExtent: 2400,
          itemCount: _chunks.length,
          itemBuilder: (context, index) {
            final slice = _chunks[index];
            final chunk = widget.text.substring(slice.start, slice.end).trim();

            return RepaintBoundary(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: index == _chunks.length - 1 ? 0 : 18,
                ),
                child: Text(
                  chunk,
                  textAlign: _textAlign(),
                  style: textStyle,
                ),
              ),
            );
          },
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
  List<_TextSlice> _pages = const <_TextSlice>[];
  bool _isPaginating = false;
  bool _paginationComplete = false;
  int _currentPage = 0;
  Size? _lastSize;
  double? _lastTextScale;
  double? _pendingProgress;
  bool _userChangedPage = false;
  int _paginationRun = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _paginationRun++;
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _TxtPagedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final textChanged = oldWidget.text != widget.text;
    final layoutChanged =
        oldWidget.settings.textSize != widget.settings.textSize ||
            oldWidget.settings.lineHeight != widget.settings.lineHeight ||
            oldWidget.settings.typeface != widget.settings.typeface ||
            oldWidget.settings.alignment != widget.settings.alignment ||
            oldWidget.textStyle != widget.textStyle;

    if (textChanged || layoutChanged) {
      _pendingProgress = textChanged
          ? widget.initialProgress
          : (_pendingProgress ?? _currentProgressFromPages());
      _resetPaginationState();
    }
  }

  void _resetPaginationState() {
    _paginationRun++;
    _pages = const <_TextSlice>[];
    _isPaginating = false;
    _paginationComplete = false;
    _lastSize = null;
    _lastTextScale = null;
    _userChangedPage = false;
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

  double _currentProgressFromPages() {
    if (widget.text.isEmpty || _pages.isEmpty) {
      return widget.initialProgress ?? 0.0;
    }
    final page = _currentPage.clamp(0, _pages.length - 1).toInt();
    return (_pages[page].start / widget.text.length).clamp(0.0, 1.0).toDouble();
  }

  int _pageIndexForProgress(double progress) {
    if (_pages.isEmpty || widget.text.isEmpty) return 0;
    final clampedProgress = progress.clamp(0.0, 1.0).toDouble();
    final targetOffset = (widget.text.length * clampedProgress).round();
    var low = 0;
    var high = _pages.length - 1;

    while (low <= high) {
      final mid = (low + high) >> 1;
      final page = _pages[mid];
      if (targetOffset < page.start) {
        high = mid - 1;
      } else if (targetOffset >= page.end) {
        low = mid + 1;
      } else {
        return mid;
      }
    }

    return low.clamp(0, _pages.length - 1).toInt();
  }

  bool get _waitingForPendingProgress {
    if (_pendingProgress == null || _pages.isEmpty || _paginationComplete) {
      return false;
    }
    final targetOffset =
        (widget.text.length * _pendingProgress!.clamp(0.0, 1.0).toDouble())
            .round();
    return _pages.last.end < targetOffset;
  }

  TextPainter _layoutText(
    String text,
    double pageWidth,
    TextScaler textScaler,
    TextStyle textStyle,
    TextAlign textAlign,
  ) {
    return TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: pageWidth);
  }

  double _lineHeightPx(TextStyle textStyle, TextScaler textScaler) {
    final baseFontSize = textStyle.fontSize ?? widget.settings.textSize;
    final scaledFontSize = math.max(8.0, textScaler.scale(baseFontSize));
    final heightMultiplier = textStyle.height ?? widget.settings.lineHeight;
    return math.max(scaledFontSize, scaledFontSize * heightMultiplier);
  }

  double _bottomFitReserve(TextStyle textStyle, TextScaler textScaler) {
    return math.max(12.0, _lineHeightPx(textStyle, textScaler) * 0.6);
  }

  int _trimTrailingWhitespace(String text, int start, int end) {
    var index = math.min(end, text.length).toInt();
    while (index > start && _isWhitespaceCodeUnit(text.codeUnitAt(index - 1))) {
      index--;
    }
    return index;
  }

  bool _fitsRange(
    String text,
    int start,
    int end,
    double pageWidth,
    double pageHeight,
    TextScaler textScaler,
    TextStyle textStyle,
    TextAlign textAlign,
  ) {
    final trimmedEnd = _trimTrailingWhitespace(text, start, end);
    if (trimmedEnd <= start) return true;

    final painter = _layoutText(
      text.substring(start, trimmedEnd),
      pageWidth,
      textScaler,
      textStyle,
      textAlign,
    );
    final lineMetrics = painter.computeLineMetrics();
    if (lineMetrics.isEmpty) return true;

    final lastLine = lineMetrics.last;
    final lastLineBottom = lastLine.baseline + lastLine.descent;
    final usableHeight = pageHeight - _bottomFitReserve(textStyle, textScaler);
    return painter.height <= usableHeight && lastLineBottom <= usableHeight;
  }

  int _previousWordBoundary(String text, int start, int offset) {
    for (var i = math.min(offset, text.length).toInt() - 1; i > start; i--) {
      if (_isWhitespaceCodeUnit(text.codeUnitAt(i))) {
        return i;
      }
    }
    return -1;
  }

  int _estimateProbeChars(Size size, TextScaler textScaler) {
    final baseFontSize = widget.textStyle.fontSize ?? widget.settings.textSize;
    final scaledFontSize = math.max(8.0, textScaler.scale(baseFontSize));
    final lineHeightPx = _lineHeightPx(widget.textStyle, textScaler);
    final linesPerPage = math.max(4, (size.height / lineHeightPx).floor());
    final averageGlyphWidth = math.max(5.0, scaledFontSize * 0.56);
    final charsPerLine = math.max(14, (size.width / averageGlyphWidth).floor());

    return math.max(128, (linesPerPage * charsPerLine * 0.65).floor());
  }

  int _findPageEnd({
    required String text,
    required int start,
    required int end,
    required double pageWidth,
    required double pageHeight,
    required TextScaler textScaler,
    required TextStyle textStyle,
    required TextAlign textAlign,
    required int probeChars,
  }) {
    final remaining = end - start;
    if (remaining <= 0) return end;

    bool fitsOffset(int offset) {
      return _fitsRange(
        text,
        start,
        start + offset,
        pageWidth,
        pageHeight,
        textScaler,
        textStyle,
        textAlign,
      );
    }

    var upper = math.min(remaining, probeChars.clamp(64, 4096)).toInt();
    while (upper < remaining && fitsOffset(upper)) {
      final nextUpper = math.min(remaining, upper * 2).toInt();
      if (nextUpper == upper) break;
      upper = nextUpper;
    }

    var low = 1;
    var high = upper;
    var best = 0;
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
      return math.min(start + 1, end).toInt();
    }

    var splitIndex = start + best;
    if (splitIndex < end) {
      final wordBoundary = _previousWordBoundary(text, start, splitIndex);
      if (wordBoundary > start &&
          _fitsRange(
            text,
            start,
            wordBoundary,
            pageWidth,
            pageHeight,
            textScaler,
            textStyle,
            textAlign,
          )) {
        splitIndex = wordBoundary;
      }
    }

    while (splitIndex > start + 1 &&
        !_fitsRange(
          text,
          start,
          splitIndex,
          pageWidth,
          pageHeight,
          textScaler,
          textStyle,
          textAlign,
        )) {
      final wordBoundary = _previousWordBoundary(text, start, splitIndex - 1);
      splitIndex = wordBoundary > start ? wordBoundary : splitIndex - 1;
    }

    return math.min(math.max(splitIndex, start + 1), end).toInt();
  }

  void _startPaginationIfNeeded(Size size, TextScaler textScaler) {
    if (size.width <= 0 || size.height <= 0 || widget.text.isEmpty) return;

    final textScale =
        textScaler.scale(widget.textStyle.fontSize ?? widget.settings.textSize);
    final sameLayout = _lastSize != null &&
        (size.width - _lastSize!.width).abs() < 1 &&
        (size.height - _lastSize!.height).abs() < 1 &&
        _lastTextScale == textScale &&
        (_isPaginating || _paginationComplete || _pages.isNotEmpty);

    if (sameLayout) return;

    final progress = _pendingProgress ?? _currentProgressFromPages();
    final run = ++_paginationRun;
    _lastSize = size;
    _lastTextScale = textScale;
    _pendingProgress = progress;
    _pages = const <_TextSlice>[];
    _currentPage = 0;
    _isPaginating = true;
    _paginationComplete = false;
    _userChangedPage = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && run == _paginationRun) {
        _paginateIncrementally(size, textScaler, run);
      }
    });
  }

  Future<void> _paginateIncrementally(
    Size size,
    TextScaler textScaler,
    int run,
  ) async {
    final text = widget.text;
    final textStyle = widget.textStyle;
    final textAlign = _textAlign();
    final pageWidth = size.width;
    final pageHeight = math.max(1.0, size.height - 4.0);
    final probeChars = _estimateProbeChars(size, textScaler);
    final pages = <_TextSlice>[];
    var start = _skipLeadingWhitespace(text, 0);
    final end = text.length;
    var lastPublishedLength = 0;
    final batchWatch = Stopwatch()..start();

    while (start < end) {
      if (!mounted || run != _paginationRun) return;

      final splitIndex = _findPageEnd(
        text: text,
        start: start,
        end: end,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        textScaler: textScaler,
        textStyle: textStyle,
        textAlign: textAlign,
        probeChars: probeChars,
      );

      pages.add(_TextSlice(start, splitIndex));
      start = _skipLeadingWhitespace(text, splitIndex);

      final shouldPublish =
          pages.length == 1 || pages.length - lastPublishedLength >= 16;
      final shouldYield = shouldPublish || batchWatch.elapsedMilliseconds >= 10;
      if (shouldPublish) {
        _publishPages(pages, complete: false, run: run);
        lastPublishedLength = pages.length;
      }
      if (shouldYield) {
        await Future<void>.delayed(Duration.zero);
        batchWatch
          ..reset()
          ..start();
      }
    }

    _publishPages(pages, complete: true, run: run);
  }

  void _publishPages(
    List<_TextSlice> pages, {
    required bool complete,
    required int run,
  }) {
    if (!mounted || run != _paginationRun) return;

    int? pageToJump;
    setState(() {
      _pages = List<_TextSlice>.unmodifiable(pages);
      _paginationComplete = complete;
      _isPaginating = !complete;

      if (_pendingProgress != null && !_userChangedPage && _pages.isNotEmpty) {
        final targetOffset =
            (widget.text.length * _pendingProgress!.clamp(0.0, 1.0).toDouble())
                .round();
        if (complete || _pages.last.end >= targetOffset) {
          _currentPage = _pageIndexForProgress(_pendingProgress!);
          _pendingProgress = null;
          pageToJump = _currentPage;
        }
      }

      if (_pages.isNotEmpty && _currentPage >= _pages.length) {
        _currentPage = _pages.length - 1;
        pageToJump = _currentPage;
      }
    });

    if (_pages.isNotEmpty && (complete || pageToJump != null)) {
      final page = pageToJump ?? _currentPage;
      _jumpToPage(page);
      widget.onPageChanged?.call(page, _pages.length);
    }
  }

  void _jumpToPage(int page) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients || _pages.isEmpty) return;
      final targetPage = page.clamp(0, _pages.length - 1).toInt();
      if (_pageController.page?.round() != targetPage) {
        _pageController.jumpToPage(targetPage);
      }
    });
  }

  void _nextPage() {
    final itemCount = _paginationComplete ? _pages.length : _pages.length + 1;
    if (_currentPage < itemCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Widget _buildLoadingPage(String message, TextStyle footerStyle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message, style: footerStyle),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final textScaler = MediaQuery.textScalerOf(context);
        const double horizontalMargin = 24.0;
        const double topMargin = 40.0;
        const double bottomMargin = 50.0;
        const double footerHeight = 32.0;

        final textAreaSize = Size(
          math.max(1.0, constraints.maxWidth - (horizontalMargin * 2)),
          math.max(
            1.0,
            constraints.maxHeight - topMargin - bottomMargin - footerHeight,
          ),
        );
        final footerStyle = widget.textStyle.copyWith(
          fontSize: 11,
          color: widget.textStyle.color?.withOpacity(0.45),
        );

        _startPaginationIfNeeded(textAreaSize, textScaler);

        if (_pages.isEmpty || _waitingForPendingProgress) {
          return _buildLoadingPage(
            _pages.isEmpty ? 'Preparing pages...' : 'Finding your place...',
            footerStyle,
          );
        }

        final itemCount =
            _paginationComplete ? _pages.length : _pages.length + 1;

        return GestureDetector(
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
            itemCount: itemCount,
            allowImplicitScrolling: false,
            physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
            onPageChanged: (index) {
              if (index >= _pages.length) return;
              _userChangedPage = true;
              if (_currentPage != index) {
                setState(() => _currentPage = index);
              }
              widget.onPageChanged?.call(index, _pages.length);
            },
            itemBuilder: (context, index) {
              if (index >= _pages.length) {
                return _buildLoadingPage(
                    'Counting remaining pages...', footerStyle);
              }

              final slice = _pages[index];
              final pageText =
                  widget.text.substring(slice.start, slice.end).trim();
              final footerText = _paginationComplete
                  ? '${index + 1} / ${_pages.length}'
                  : '${index + 1} / ...';

              return RepaintBoundary(
                child: Container(
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
                          pageText,
                          textAlign: _textAlign(),
                          style: widget.textStyle,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      SizedBox(
                        height: footerHeight,
                        child: Center(
                          child: Text(footerText, style: footerStyle),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
