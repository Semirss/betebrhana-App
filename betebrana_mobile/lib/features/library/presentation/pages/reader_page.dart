import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:betebrana_mobile/features/library/data/book_download_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:betebrana_mobile/core/config/app_config.dart';
import 'package:betebrana_mobile/core/network/dio_client.dart';
import 'package:betebrana_mobile/features/library/data/offline_book_service.dart';
import 'package:betebrana_mobile/features/library/domain/entities/book.dart';
import 'package:betebrana_mobile/core/theme/app_theme.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key, required this.book, this.rentalDueDate});

  final Book book;
  final DateTime? rentalDueDate;

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

  // New state variables
  double _textScale = 1.0;
  static const double _minTextScale = 0.8;
  static const double _maxTextScale = 2.0;
  static const double _textScaleStep = 0.1;

  // Theme management
  int _currentThemeIndex = 0;
  late List<ThemeData> _themes;

  @override
  void initState() {
    super.initState();
    _initThemes();
    _offlineBookService = OfflineBookService();
    _initTxtFuture();
    _refreshOfflineState();
    // Hide status bar for immersive reading
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }

  void _initThemes() {
    _themes = [
      AppTheme.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFFDFDFD),
        textTheme: AppTheme.light().textTheme.apply(fontFamily: 'Georgia'),
      ),
      AppTheme.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        textTheme: AppTheme.dark().textTheme.apply(fontFamily: 'Georgia'),
      ),
      ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5EFE1), // Sepia background
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.brown,
          background: const Color(0xFFF5EFE1),
          surface: const Color(0xFFF5EFE1),
          onBackground: const Color(0xFF4E342E),
          onSurface: const Color(0xFF4E342E),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF4E342E), fontFamily: 'Georgia'),
        ),
      ),
      ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF000000), // OLED Black
        colorScheme: const ColorScheme.dark(
          primary: Colors.grey,
          background: Color(0xFF000000),
          surface: Color(0xFF000000),
          onBackground: Color(0xFFB0B0B0),
          onSurface: Color(0xFFB0B0B0),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFB0B0B0), fontFamily: 'Georgia'),
        ),
      ),
    ];
  }

  @override
  void dispose() {
    // Restore system UI overlays
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  void _initTxtFuture() {
    final type = (widget.book.fileType ?? '').toLowerCase();

    // If book is downloaded and has local file path, read from local
    if (widget.book.isDownloaded == true && widget.book.localFilePath != null) {
      _txtFuture = _loadLocalTxtContent(widget.book);
    } else if (type == 'txt') {
      // Fall back to server loading if not downloaded
      _txtFuture = _loadTxtContent(widget.book);
    } else {
      _txtFuture = Future.value('');
    }
  }

  Future<String> _loadLocalTxtContent(Book book) async {
    try {
      if (book.localFilePath == null) {
        throw Exception('No local file path available');
      }

      final localFile = File(book.localFilePath!);
      if (!await localFile.exists()) {
        throw Exception('Local file not found');
      }

      final content = await localFile.readAsString();
      return content;
    } catch (e) {
      try {
        final text = await _offlineBookService.readTxtContent(book.id);
        if (text.isNotEmpty) return text;
      } catch (_) {}

      try {
        final bookId = int.tryParse(book.id);
        if (bookId != null) {
          final downloadService = BookDownloadService();
          return await downloadService.getBookContent(bookId);
        }
      } catch (_) {}

      throw Exception('Failed to load local book content: $e');
    }
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

    final url = _buildDocumentUrl(book.filePath);
    if (url == null) throw Exception('This book has no associated file.');

    final dio = DioClient.instance.dio;
    final response = await dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain),
    );
    return response.data ?? '';
  }

  String? _buildDocumentUrl(String? filePath) {
    if (filePath == null || filePath.isEmpty) return null;
    var path = filePath.trim();
    if (path.startsWith('/')) path = path.substring(1);
    if (path.startsWith('documents/')) path = path.substring('documents/'.length);
    return '${AppConfig.documentsBaseUrl}/$path';
  }

  Future<void> _downloadForOffline() async {
    setState(() => _downloadInProgress = true);
    try {
      final text = await _txtFuture;
      if (text.isEmpty) throw Exception('Book is empty');

      final expiresAt = (widget.rentalDueDate ??
              DateTime.now().add(const Duration(days: 21)))
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

  void _zoomIn() {
    setState(() {
      if (_textScale < _maxTextScale) _textScale += _textScaleStep;
    });
  }

  void _zoomOut() {
    setState(() {
      if (_textScale > _minTextScale) _textScale -= _textScaleStep;
    });
  }

  void _changeTheme() {
    setState(() {
      _currentThemeIndex = (_currentThemeIndex + 1) % _themes.length;
    });
  }

  String _getThemeName() {
    switch (_currentThemeIndex) {
      case 0: return 'Light';
      case 1: return 'Dark';
      case 2: return 'Sepia';
      case 3: return 'OLED';
      default: return 'Light';
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = (widget.book.fileType ?? '').toLowerCase();
    final theme = _themes[_currentThemeIndex];

    return Theme(
      data: theme,
      child: DefaultTabController(
        length: type == 'txt' ? 2 : 1,
        // Start with the Paged view (index 1) as it is the "premium" experience
        initialIndex: type == 'txt' ? 1 : 0, 
        child: Scaffold(
          // Use a transparent app bar that reveals on tap in a real app,
          // but here we keep it simple.
          appBar: AppBar(
            elevation: 0,
            backgroundColor: theme.scaffoldBackgroundColor,
            foregroundColor: theme.colorScheme.onBackground,
            title: Text(
              widget.book.title.isEmpty ? 'Reader' : widget.book.title,
              style: const TextStyle(fontSize: 16),
            ),
            bottom: type == 'txt'
                ? TabBar(
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onBackground.withOpacity(0.5),
                    indicatorColor: theme.colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Scroll'),
                      Tab(text: 'Paged'),
                    ],
                  )
                : null,
            actions: [
              if (type == 'txt') ...[
                IconButton(
                  onPressed: _zoomOut,
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                ),
                Center(
                    child: Text(
                  '${(_textScale * 100).round()}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )),
                IconButton(
                  onPressed: _zoomIn,
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _changeTheme,
                  icon: Icon(
                    _currentThemeIndex == 1 || _currentThemeIndex == 3 
                        ? Icons.light_mode 
                        : Icons.dark_mode
                  ),
                  tooltip: 'Theme: ${_getThemeName()}',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'download') {
                      if (!(widget.book.isDownloaded == true || _hasOfflineCopy)) {
                         _downloadForOffline();
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'download',
                      enabled: !_downloadInProgress,
                      child: Row(
                        children: [
                          Icon(
                            (widget.book.isDownloaded == true || _hasOfflineCopy)
                                ? Icons.check
                                : Icons.download,
                            color: theme.colorScheme.onSurface,
                          ),
                          const SizedBox(width: 12),
                          Text((widget.book.isDownloaded == true || _hasOfflineCopy)
                              ? 'Available Offline'
                              : 'Download'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          body: type == 'txt'
              ? FutureBuilder<String>(
                  future: _txtFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final text = snapshot.data ?? '';
                    if (text.isEmpty) {
                      return const Center(child: Text('Book is empty.'));
                    }

                    return TabBarView(
                      physics: const NeverScrollableScrollPhysics(), // Disable swipe between tabs
                      children: [
                        _TxtScrollView(text: text, textScale: _textScale),
                        _TxtPagedView(
                          text: text, 
                          textScale: _textScale,
                          // Pass text style to ensure pagination calculation uses correct metrics
                          textStyle: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 18 * _textScale,
                            height: 1.6,
                            color: theme.colorScheme.onBackground,
                          ) ?? TextStyle(
                             fontSize: 18 * _textScale,
                             height: 1.6,
                             color: theme.colorScheme.onBackground,
                             fontFamily: 'Georgia'
                          ),
                        ),
                      ],
                    );
                  },
                )
              : const Center(child: Text('Format not supported')),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SCROLL VIEW (Standard)
// -----------------------------------------------------------------------------
class _TxtScrollView extends StatelessWidget {
  const _TxtScrollView({required this.text, required this.textScale});

  final String text;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 18 * textScale,
            height: 1.6,
            fontFamily: 'Georgia', // Serif is better for reading
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
    required this.textScale,
    required this.textStyle,
  });

  final String text;
  final double textScale;
  final TextStyle textStyle;

  @override
  State<_TxtPagedView> createState() => _TxtPagedViewState();
}

class _TxtPagedViewState extends State<_TxtPagedView> {
  late PageController _pageController;
  List<String> _pages = [];
  bool _isPaginating = true;
  int _currentPage = 0;
  Size? _lastSize;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant _TxtPagedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Repaginate if text style (scale/font) or content changes
    if (oldWidget.textScale != widget.textScale || 
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
      final textPosition = textPainter.getPositionForOffset(Offset(pageWidth, pageHeight));
      
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
        // Reset to page 0 if out of bounds, or keep current ratio
        if (_currentPage >= _pages.length) _currentPage = 0;
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
                onPageChanged: (index) => setState(() => _currentPage = index),
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
                            textAlign: TextAlign.justify,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Footer (Progress)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${((_currentPage + 1) / _pages.length * 100).toInt()}%',
                       style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      '${_currentPage + 1} of ${_pages.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Progress Bar Line
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: (_currentPage + 1) / _pages.length,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
                ),
                minHeight: 2,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}