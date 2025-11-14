import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

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
  static const double _maxTextScale = 2.5;
  static const double _textScaleStep = 0.1;
  
  // Theme management
  int _currentThemeIndex = 0;
  final List<ThemeData> _themes = [
    AppTheme.light(),
    AppTheme.dark(),
    ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.tanForeground,
        background: AppTheme.tanBackground,
        onBackground: AppTheme.tanForeground,
      ),
    ),
    ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.blueForeground,
        background: AppTheme.blueBackground,
        onBackground: AppTheme.blueForeground,
      ),
    ),
    ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTheme.greenForeground,
        background: AppTheme.greenBackground,
        onBackground: AppTheme.greenForeground,
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _offlineBookService = OfflineBookService();
    _initTxtFuture();
  }

  void _initTxtFuture() {
    final type = (widget.book.fileType ?? '').toLowerCase();
    if (type == 'txt') {
      _txtFuture = _loadTxtContent(widget.book);
    } else {
      _txtFuture = Future.value('');
    }
  }

  Future<void> _refreshOfflineState() async {
    final entry = await _offlineBookService.getEntryForBook(widget.book.id);
    if (!mounted) return;
    setState(() {
      _hasOfflineCopy = entry != null;
      _offlineExpiresAt = entry?.expiresAt;
    });
  }

  Future<String> _loadTxtContent(Book book) async {
    // Prefer offline encrypted copy if available and not expired.
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
    } catch (_) {
      // If offline read fails for any reason, fall back to network below.
    }

    final url = _buildDocumentUrl(book.filePath);
    if (url == null) {
      throw Exception('This book has no associated file.');
    }

    final dio = DioClient.instance.dio;
    final response = await dio.get<String>(
      url,
      options: Options(responseType: ResponseType.plain),
    );
    return response.data ?? '';
  }

  Future<void> _downloadForOffline() async {
    setState(() {
      _downloadInProgress = true;
    });

    try {
      final text = await _txtFuture;
      if (text.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing to download: book is empty.')),
        );
        setState(() {
          _downloadInProgress = false;
        });
        return;
      }

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
      setState(() {
        _downloadInProgress = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download book: $e')),
      );
    }
  }

  Future<void> _deleteOfflineCopy() async {
    setState(() {
      _downloadInProgress = true;
    });

    try {
      await _offlineBookService.deleteOfflineCopy(widget.book.id);
      if (!mounted) return;
      setState(() {
        _hasOfflineCopy = false;
        _offlineExpiresAt = null;
        _downloadInProgress = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline copy deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloadInProgress = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete offline copy: $e')),
      );
    }
  }

  // Zoom methods
  void _zoomIn() {
    setState(() {
      if (_textScale < _maxTextScale) {
        _textScale += _textScaleStep;
      }
    });
  }

  void _zoomOut() {
    setState(() {
      if (_textScale > _minTextScale) {
        _textScale -= _textScaleStep;
      }
    });
  }

  void _resetZoom() {
    setState(() {
      _textScale = 1.0;
    });
  }

  // Theme methods
  void _changeTheme() {
    setState(() {
      _currentThemeIndex = (_currentThemeIndex + 1) % _themes.length;
    });
  }

  String _getThemeName() {
    switch (_currentThemeIndex) {
      case 0:
        return 'Light';
      case 1:
        return 'Dark';
      case 2:
        return 'Sepia';
      case 3:
        return 'Blue';
      case 4:
        return 'Green';
      default:
        return 'Light';
    }
  }

  IconData _getThemeIcon() {
    switch (_currentThemeIndex) {
      case 0:
        return Icons.light_mode;
      case 1:
        return Icons.dark_mode;
      case 2:
        return Icons.filter_vintage;
      case 3:
        return Icons.water_drop;
      case 4:
        return Icons.nature;
      default:
        return Icons.light_mode;
    }
  }
@override
Widget build(BuildContext context) {
  final type = (widget.book.fileType ?? '').toLowerCase();

  return Theme(
    data: _themes[_currentThemeIndex],
    child: DefaultTabController(
      length: type == 'txt' ? 2 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.book.title.isEmpty
              ? 'Reader'
              : widget.book.title),
          bottom: type == 'txt'
              ? const TabBar(
                  tabs: [
                    Tab(text: 'Scroll'),
                    Tab(text: 'Paged'),
                  ],
                )
              : null,
          actions: [
            // Zoom controls - only for scroll view
            if (type == 'txt') ...[
              IconButton(
                onPressed: _zoomOut,
                icon: const Icon(Icons.zoom_out),
                tooltip: 'Zoom Out',
              ),
              PopupMenuButton<double>(
                icon: Text('${(_textScale * 100).round()}%'),
                tooltip: 'Text Size',
                onSelected: (value) {
                  setState(() {
                    _textScale = value;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 0.8,
                    child: Text('80%'),
                  ),
                  const PopupMenuItem(
                    value: 1.0,
                    child: Text('100%'),
                  ),
                  const PopupMenuItem(
                    value: 1.2,
                    child: Text('120%'),
                  ),
                  const PopupMenuItem(
                    value: 1.5,
                    child: Text('150%'),
                  ),
                  const PopupMenuItem(
                    value: 2.0,
                    child: Text('200%'),
                  ),
                ],
              ),
              IconButton(
                onPressed: _zoomIn,
                icon: const Icon(Icons.zoom_in),
                tooltip: 'Zoom In',
              ),
              const VerticalDivider(thickness: 1, indent: 10, endIndent: 10),
            ],
            
            // Theme changer
            IconButton(
              onPressed: _changeTheme,
              icon: Icon(_getThemeIcon()),
              tooltip: 'Change Theme (${_getThemeName()})',
            ),
            
            // Offline download/delete
            if (type == 'txt') ...[
              IconButton(
                onPressed: _downloadInProgress
                    ? null
                    : () {
                        if (_hasOfflineCopy) {
                          _deleteOfflineCopy();
                        } else {
                          _downloadForOffline();
                        }
                      },
                icon: _downloadInProgress
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _hasOfflineCopy
                            ? Icons.cloud_done
                            : Icons.download,
                      ),
                tooltip: _hasOfflineCopy
                    ? 'Delete offline copy'
                    : 'Download for offline',
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
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Failed to load book: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final text = snapshot.data ?? '';
                  if (text.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('This book has no content.'),
                      ),
                    );
                  }

                  return TabBarView(
                    children: [
                      _TxtScrollView(text: text, textScale: _textScale),
                      _TxtPagedView(text: text), // No zoom parameter
                    ],
                  );
                },
              )
            : _UnsupportedTypeView(type: type),
      ),
    ),
  );
}

  String? _buildDocumentUrl(String? filePath) {
    if (filePath == null || filePath.isEmpty) return null;
    var path = filePath.trim();
    if (path.startsWith('/')) {
      path = path.substring(1);
    }
    if (path.startsWith('documents/')) {
      path = path.substring('documents/'.length);
    }
    return '${AppConfig.documentsBaseUrl}/$path';
  }
}

class _TxtScrollView extends StatelessWidget {
  const _TxtScrollView({required this.text, required this.textScale});

  final String text;
  final double textScale;

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16 * textScale,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TxtPagedView extends StatefulWidget {
  const _TxtPagedView({required this.text});

  final String text;

  @override
  State<_TxtPagedView> createState() => _TxtPagedViewState();
}

class _TxtPagedViewState extends State<_TxtPagedView> {
  late PageController _pageController;
  late List<String> _pages;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pages = _paginate(widget.text);
  }

  List<String> _paginate(String content) {
    if (content.isEmpty) return [''];
    
    // Fixed character count for consistent 100% zoom
    const int charsPerPage = 1500; // Optimized for readability at 100%
    
    final pages = <String>[];
    var start = 0;
    final contentLength = content.length;
    
    while (start < contentLength) {
      int end = start + charsPerPage;
      
      // If we're at the end of content
      if (end >= contentLength) {
        pages.add(content.substring(start).trim());
        break;
      }
      
      // Find the best break point
      int bestBreak = -1;
      
      // Priority 1: Paragraph break
      int paragraphBreak = content.lastIndexOf('\n\n', end);
      if (paragraphBreak > start + (charsPerPage * 0.4)) {
        bestBreak = paragraphBreak + 2;
      }
      
      // Priority 2: Single newline
      if (bestBreak == -1) {
        int newlineBreak = content.lastIndexOf('\n', end);
        if (newlineBreak > start + (charsPerPage * 0.6)) {
          bestBreak = newlineBreak + 1;
        }
      }
      
      // Priority 3: Sentence break
      if (bestBreak == -1) {
        int sentenceBreak = content.lastIndexOf('. ', end);
        if (sentenceBreak > start + (charsPerPage * 0.7)) {
          bestBreak = sentenceBreak + 2;
        }
      }
      
      // Priority 4: Word break
      if (bestBreak == -1) {
        int wordBreak = content.lastIndexOf(' ', end);
        if (wordBreak > start + (charsPerPage * 0.8)) {
          bestBreak = wordBreak + 1;
        }
      }
      
      // If no good break found, break at calculated position
      if (bestBreak == -1 || bestBreak <= start) {
        bestBreak = end;
      }
      
      // Ensure we don't go beyond content length
      bestBreak = bestBreak.clamp(start + 1, contentLength);
      
      String pageContent = content.substring(start, bestBreak).trim();
      if (pageContent.isNotEmpty) {
        pages.add(pageContent);
      }
      
      start = bestBreak;
    }
    
    if (pages.isEmpty) {
      pages.add(content);
    }
    
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: _pages.length,
          onPageChanged: (page) {
            setState(() {
              _currentPage = page;
            });
          },
          itemBuilder: (context, index) {
            final pageText = _pages[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  children: [
                    Expanded(
                      child: Text(
                        pageText,
                        style: const TextStyle(
                          fontSize: 16, // Fixed at 100%
                          height: 1.6,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                    // Page number
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        
        // Bottom navigation
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous page arrow
                if (_currentPage > 0)
                  GestureDetector(
                    onTap: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 48),
                
                // Total pages indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Page ${_currentPage + 1} of ${_pages.length}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                
                // Next page arrow
                if (_currentPage < _pages.length - 1)
                  GestureDetector(
                    onTap: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
class _UnsupportedTypeView extends StatelessWidget {
  const _UnsupportedTypeView({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final display = type.isEmpty ? 'this file type' : type;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Reader for $display is not implemented yet. '
          'TXT files are fully supported; PDF/EPUB/DOCX support will be added next.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}