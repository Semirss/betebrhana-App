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
import '../widgets/reader_header.dart';
import '../widgets/reader_bottom_controls.dart';
import '../widgets/display_settings_sheet.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  int _currentPage = 0;
  int _totalPages = 1;
  double _currentProgress = 0.0;
  double? _initialProgress;

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
      }
    });
    _offlineBookService = OfflineBookService();
    _initTxtFuture();
    _refreshOfflineState();
    _fetchAds();
    // Hide status bar for immersive reading
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
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
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bookmark removed')));
       }
    } else {
       await prefs.setDouble(key, _currentProgress);
       setState(() => _isBookmarked = true);
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bookmark saved!')));
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

    // Tick every 50ms, scroll by speed factor
    _autoScrollTimer =
        Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!_scrollController.hasClients ||
          !_isAutoScrolling ||
          _isLockEnabled) {
        timer.cancel();
        return;
      }
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      final delta =
          _settings.autoScrollSpeed * 2.0; // Adjust multiplier as needed

      if (currentScroll < maxScroll) {
        _scrollController.jumpTo(currentScroll + delta);
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
    );
  }

  void _handleSearch() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    // In a real app we'd highlight or jump to the result.
    // For now we just record it.
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
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReaderBottomControls(
                isBookmarked: _isBookmarked,
                isAutoScrolling: _isAutoScrolling,
                isOrientationLandscape: _isOrientationLandscape,
                onShowChapterList: () {},
                onToggleBookmark: _toggleBookmark,
                onToggleAutoScroll: _toggleAutoScroll,
                onToggleOrientation: _toggleOrientation,
                onShowDisplaySettings: _showDisplaySettingsSheet,
              ),
              if (_sharedAd != null && !_showInterstitial)
                GestureDetector(
                    onTap: () async {
                      if (_sharedAd!['redirect_link'] != null) {
                        final url = Uri.parse(_sharedAd!['redirect_link']);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url,
                              mode: LaunchMode.externalApplication);
                        }
                      }
                    },
                    child: _buildBannerAd()),
            ],
          ),
          body: Column(
            children: [
              ReaderHeader(
                title: widget.book.title.isEmpty ? 'Reader' : widget.book.title,
                pageInfo: 'Page ${_currentPage + 1}',
                isSearching: _isSearching,
                isLockEnabled: _isLockEnabled,
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
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
                onToggleLock: () =>
                    setState(() => _isLockEnabled = !_isLockEnabled),
                onSearchNext: () {},
              ),
              if (type == 'txt')
                Container(
                  color: currentTheme.scaffoldBackgroundColor,
                  child: TabBar(
                    labelColor: const Color(0xFFFF7A3B),
                    unselectedLabelColor:
                        currentTheme.colorScheme.onSurface.withOpacity(0.5),
                    indicatorColor: const Color(0xFFFF7A3B),
                    indicatorWeight: 3.0,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.normal, fontSize: 14),
                    tabs: const [
                      Tab(text: 'Scroll'),
                      Tab(text: 'Paged'),
                    ],
                  ),
                ),
              Expanded(
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
                                  ),
                                  _TxtPagedView(
                                    text: text,
                                    settings: _settings,
                                    initialProgress: _initialProgress,
                                    textStyle: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontSize: _settings.textSize,
                                          height: _settings.lineHeight,
                                          color: theme.colorScheme.onSurface,
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
                                        if (mounted &&
                                            (_currentPage != page ||
                                                _totalPages != total)) {
                                          setState(() {
                                            _currentPage = page;
                                            _totalPages = total;
                                            if (total > 1) {
                                              _currentProgress = page / (total - 1);
                                            } else {
                                              _currentProgress = 0.0;
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
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (_sharedAd!['logo_path'] != null)
                                      Container(
                                        width: 90,
                                        height: 90,
                                        margin:
                                            const EdgeInsets.only(bottom: 20),
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
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 28, vertical: 12),
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
                                              backgroundColor: Colors.white24,
                                            ),
                                            Text(
                                              '$_adCountdown',
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
                                        'Ad — please wait',
                                        style: TextStyle(
                                            color: Colors.white54,
                                            fontSize: 13),
                                      ),
                                    ] else ...[
                                      // Countdown finished — show action buttons
                                      ElevatedButton(
                                        onPressed: () async {
                                          if (_sharedAd!['redirect_link'] !=
                                              null) {
                                            final url = Uri.parse(
                                                _sharedAd!['redirect_link']);
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(url,
                                                  mode: LaunchMode
                                                      .externalApplication);
                                            }
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black87,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 24, vertical: 14),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.open_in_new, size: 18),
                                            SizedBox(width: 8),
                                            Text('Visit Sponsor',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      TextButton(
                                        onPressed: () => setState(
                                            () => _showInterstitial = false),
                                        child: const Text('Close and Read Book',
                                            style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 15)),
                                      ),
                                    ],
                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ))
                            ],
                          ),
                        ),
                      ),
                  ],
                ), // end Stack
              ), // end Expanded
            ],
          ), // end body Column
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
  });

  final String text;
  final ReaderSettings settings;
  final ScrollController scrollController;
  final String searchQuery;
  final double? initialProgress;

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
    if (!oldWidget.scrollController.hasClients && widget.scrollController.hasClients) {
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

    return Scrollbar(
      controller: widget.scrollController,
      child: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
  });

  final String text;
  final ReaderSettings settings;
  final TextStyle textStyle;
  final bool isLockEnabled;
  final double? initialProgress;
  final Function(int, int)? onPageChanged;

  @override
  State<_TxtPagedView> createState() => _TxtPagedViewState();
}

class _TxtPagedViewState extends State<_TxtPagedView> {
  late PageController _pageController;
  List<String> _pages = [];
  bool _isPaginating = true;
  int _currentPage = 0;
  Size? _lastSize;
  bool _hasSetInitialPage = false;

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
        oldWidget.textStyle != widget.textStyle ||
        oldWidget.text != widget.text) {
      _isPaginating = true; // Trigger layout builder to recalculate
    }
  }

  /// The magic happens here: Calculates pages based on ACTUAL layout dimensions
  Future<void> _paginate(Size size) async {
    // If size hasn't changed materially, don't re-calculate
    if (_lastSize != null &&
        (size.width - _lastSize!.width).abs() < 1 &&
        (size.height - _lastSize!.height).abs() < 1 &&
        !_isPaginating) {
      return;
    }

    _lastSize = size;

    // Defer to next frame to allow UI to show loading state
    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;

    final pages = <String>[];
    final text = widget.text;
    final textSpan = TextSpan(text: text, style: widget.textStyle);
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    int start = 0;
    int end = text.length;

    // Safety margin to prevent edge clipping
    final double pageHeight = size.height;
    final double pageWidth = size.width;

    while (start < end) {
      // Create a painter for the remaining text
      // We take a chunk to avoid processing huge strings at once
      int estimatedChunkSize = 3000; // Heuristic
      int chunkEnd = math.min(start + estimatedChunkSize, end);
      String chunk = text.substring(start, chunkEnd);

      textPainter.text = TextSpan(text: chunk, style: widget.textStyle);
      textPainter.layout(maxWidth: pageWidth);

      // If the whole chunk fits, great. If not, we need to find where to cut.
      // But typically, the chunk is bigger than a page.

      // Get the offset position at the bottom-right corner of the available space
      // We look for the character index at the very end of the box
      final textPosition =
          textPainter.getPositionForOffset(Offset(pageWidth, pageHeight));

      // The offset is relative to the chunk start
      int splitIndex = start + textPosition.offset;

      // Ensure we make progress
      if (splitIndex <= start) {
        // Fallback: just take next 100 chars if layout fails (shouldn't happen)
        splitIndex = math.min(start + 100, end);
      }

      // If we haven't reached the end of the book, we need to snap to a word boundary
      if (splitIndex < end) {
        // Find the last whitespace before the split point to avoid cutting words
        int safeSplit = text.lastIndexOf(RegExp(r'\s'), splitIndex);

        // If no whitespace found in reasonable distance, just hard cut
        if (safeSplit > start) {
          splitIndex = safeSplit;
        }
      }

      pages.add(text.substring(start, splitIndex).trim());
      start = splitIndex;

      // Skip leading whitespace for the next page
      while (start < end && RegExp(r'\s').hasMatch(text[start])) {
        start++;
      }
    }

    if (mounted) {
      setState(() {
        _pages = pages;
        _isPaginating = false;
        
        if (widget.initialProgress != null && !_hasSetInitialPage && _pages.isNotEmpty) {
           _currentPage = (widget.initialProgress! * (_pages.length - 1)).round();
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
        // Define margins
        const double horizontalMargin = 24.0;
        const double verticalMargin = 32.0;

        // Calculate the actual box size for text
        final Size textAreaSize = Size(
          constraints.maxWidth - (horizontalMargin * 2),
          constraints.maxHeight - (verticalMargin * 2) - 40, // -40 for footer
        );

        // Trigger pagination if needed
        if (_isPaginating || _lastSize != textAreaSize) {
          _paginate(textAreaSize);
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
            // The PageView
            GestureDetector(
              // Tap left/right logic
              onTapUp: (details) {
                final width = MediaQuery.of(context).size.width;
                if (details.localPosition.dx > width * 0.66) {
                  _nextPage();
                } else if (details.localPosition.dx < width * 0.33) {
                  _previousPage();
                } else {
                  // Center tap: toggle UI (optional, left empty here)
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
                    color: Colors.transparent, // Capture taps
                    padding: const EdgeInsets.symmetric(
                      horizontal: horizontalMargin,
                      vertical: verticalMargin,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Text(
                            _pages[index],
                            style: widget.textStyle,
                          ),
                        ),
                        // Mini Footer with progress
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Center(
                            child: Text(
                              '${index + 1} / ${_pages.length}',
                              style: widget.textStyle.copyWith(
                                  fontSize: 12,
                                  color:
                                      widget.textStyle.color?.withOpacity(0.5)),
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
