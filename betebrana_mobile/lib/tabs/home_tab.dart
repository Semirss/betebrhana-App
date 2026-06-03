import 'dart:async';
import 'dart:math' as math;
import 'package:betebrana_mobile/main_library_page.dart';
import 'package:betebrana_mobile/core/config/app_config.dart';
import 'package:betebrana_mobile/core/network/dio_client.dart';
import 'package:betebrana_mobile/core/services/language_service.dart';
import 'package:betebrana_mobile/core/theme/app_theme.dart';
import 'package:betebrana_mobile/features/library/domain/entities/book.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_bloc.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_event.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_state.dart';
import 'package:betebrana_mobile/features/library/presentation/pages/book_details_page.dart';
import 'package:betebrana_mobile/widgets/book_cover_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  void refresh(GlobalKey<HomeTabState> key) {
    key.currentState?.refresh();
  }

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  final GlobalKey<_AdSliderState> _adKey = GlobalKey<_AdSliderState>();
  PageController? _pageController;
  int _currentIndex = 0;
  Timer? _carouselTimer;

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  void refresh() {
    _adKey.currentState?.refresh();
    DefaultCacheManager().emptyCache();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    context.read<LibraryBloc>().add(const LibraryRefreshed());
  }

  void _initControllerIfNeeded(int totalBooks) {
    if (_pageController == null) {
      _currentIndex = totalBooks > 2 ? 1 : 0;
      _pageController = PageController(viewportFraction: 0.65, initialPage: _currentIndex);
      _startCarouselTimer();
    }
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || _pageController == null || !_pageController!.hasClients) return;
      final libraryBloc = context.read<LibraryBloc>();
      if (libraryBloc.state is LibraryLoaded) {
        final books = (libraryBloc.state as LibraryLoaded).books;
        if (books.isNotEmpty) {
          int nextPage = _currentIndex + 1;
          if (nextPage >= books.length) {
            nextPage = 0;
          }
          _pageController!.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _goDetails(BuildContext context, Book book) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailsPage(book: book))).then((_) {
      context.read<LibraryBloc>().add(const LibraryRefreshed());
    });
  }

  String _queueSubtitleText(Book book) {
    final info = book.queueInfo;

    if (book.userHasRental) {
      return 'Rented';
    }

    if (info == null) {
      if (!book.isAvailable) {
        return 'Currently unavailable';
      }
      return 'Available';
    }

    if (info.hasReservation) {
      final expiresAt = info.expiresAt;
      if (expiresAt != null) {
        final now = DateTime.now();
        final difference = expiresAt.difference(now);
        
        if (difference.inHours > 0) {
          return 'Reserved - ${difference.inHours}h ${difference.inMinutes.remainder(60)}m left';
        } else if (difference.inMinutes > 0) {
          return 'Reserved - ${difference.inMinutes}m left';
        } else {
          return 'Reserved - Expiring soon';
        }
      }
      return 'Reserved for you';
    }

    if (info.userInQueue) {
      if (info.userPosition > 0) {
        return 'In queue (position ${info.userPosition})';
      }
      return 'In queue';
    }

    if (info.totalInQueue > 0) {
      return 'Queue: ${info.totalInQueue} waiting';
    }

    return book.isAvailable ? 'Available' : 'Currently unavailable';
  }

  Color _getQueueStatusColor(BuildContext context, Book book) {
    if (book.userHasRental) {
      return Colors.green;
    }
    final info = book.queueInfo;
    if (info?.hasReservation ?? false) {
      return Colors.green;
    }
    if (info?.userInQueue ?? false) {
      return Colors.orange;
    }
    if (book.isAvailable) {
      return Theme.of(context).colorScheme.secondary;
    }
    return Theme.of(context).colorScheme.error;
  }

  Widget _buildBookCard(Book book, int index, int currentIndex, double viewportHeight, double viewportWidth) {
    final coverUrl = book.coverImagePath?.isNotEmpty == true 
        ? AppConfig.resolveUrl(book.coverImagePath)
        : null;

    return AnimatedBuilder(
      animation: _pageController!,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController!.position.haveDimensions) {
          value = _pageController!.page! - index;
          // Make scaling more subtle and professional
          value = (1 - (value.abs() * 0.1)).clamp(0.9, 1.0);
        } else {
          value = index == currentIndex ? 1.0 : 0.9;
        }

        return Align(
          alignment: Alignment.center,
          child: Transform.scale(
            scale: Curves.easeInOut.transform(value),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (index == currentIndex) {
            _goDetails(context, book);
          } else {
            _pageController!.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        child: AspectRatio(
          aspectRatio: 0.65, // Perfect book cover proportions
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 15,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.book, size: 50, color: Colors.grey),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.book, size: 50, color: Colors.grey),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        if (state is LibraryLoading || state is LibraryInitial) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (state is LibraryError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load books',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is LibraryLoaded) {
          final books = state.books;
          if (books.isEmpty) {
            return const Scaffold(body: Center(child: Text('No books available')));
          }

          _initControllerIfNeeded(books.length);

          final safeIndex = _currentIndex < books.length ? _currentIndex : 0;
          final currentBook = books[safeIndex];
          final currentCoverUrl = currentBook.coverImagePath?.isNotEmpty == true 
              ? AppConfig.resolveUrl(currentBook.coverImagePath)
              : null;
              
          final arrivals = books.length > 1 ? books.sublist(1, math.min(books.length, 10)) : <Book>[];
          final trending = books.reversed.take(5).toList();

          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: LayoutBuilder(
              builder: (context, constraints) {
                final viewportHeight = constraints.maxHeight;
                final viewportWidth = constraints.maxWidth;

                return SingleChildScrollView(
                  child: Stack(
                    children: [
                      // 1. Animated Background (Stretches exactly 55% of the viewport)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: viewportHeight * 0.55,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 600),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: currentCoverUrl != null
                              ? Container(
                                  key: ValueKey<String>(currentCoverUrl),
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: CachedNetworkImageProvider(currentCoverUrl),
                                      fit: BoxFit.cover,
                                      colorFilter: ColorFilter.mode(
                                        Colors.black.withOpacity(0.3),
                                        BlendMode.darken,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  key: const ValueKey('placeholder'),
                                  color: Colors.grey.shade800,
                                ),
                        ),
                      ),

                      // 2. White Bottom Section (Covers the rest of the scrollable content)
                      Positioned(
                        top: viewportHeight * 0.45,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                        ),
                      ),

                      // 3. The Content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── MAIN PAGE VIEWPORT ──
                          // This container perfectly occupies exactly one screen height
                          Container(
                            height: viewportHeight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header Row (Discover & Search)
                                SafeArea(
                                  bottom: false,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Discover',
                                          style: TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.search, color: Colors.white, shadows: [Shadow(color: Colors.black45, blurRadius: 4)]),
                                          onPressed: () {
                                            showSearch(
                                              context: context,
                                              delegate: _QuickSearchDelegate(books: books),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                
                                const Spacer(flex: 1),
                                
                                // Carousel
                                SizedBox(
                                  height: viewportHeight * 0.55, 
                                  child: PageView.builder(
                                    controller: _pageController,
                                    onPageChanged: (index) {
                                      setState(() {
                                        _currentIndex = index;
                                      });
                                    },
                                    itemCount: books.length,
                                    itemBuilder: (context, index) {
                                      return _buildBookCard(books[index], index, safeIndex, viewportHeight, viewportWidth);
                                    },
                                  ),
                                ),
                                
                                const Spacer(flex: 1),
                                
                                // Book Details (Title, Author)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24),
                                  child: Column(
                                    children: [
                                      Text(
                                        currentBook.title.isEmpty ? 'Untitled' : currentBook.title,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                          letterSpacing: -0.5,
                                          height: 1.2,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        currentBook.author.isEmpty ? 'Unknown author' : 'By ${currentBook.author}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      
                                      // Queue Status Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _getQueueStatusColor(context, currentBook).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _queueSubtitleText(currentBook),
                                          style: TextStyle(
                                            color: _getQueueStatusColor(context, currentBook),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        '${currentBook.availableCopies}/${currentBook.totalCopies} available',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(flex: 2), // Pushes content up comfortably inside the viewport
                              ],
                            ),
                          ),
                          
                          // ── SCROLLABLE FOOTER CONTENT ──
                          // This starts exactly after scrolling down 1 full page

                          // ── New Arrivals ──
                          if (arrivals.isNotEmpty) ...[
                            _SectionHeader(
                              title: context.read<LanguageBloc>().state.t('New Arrivals'),
                              onSeeAll: () => context
                                  .findAncestorStateOfType<MainLibraryViewState>()
                                  ?.switchToTab(1),
                            ),
                            SizedBox(
                              height: 165,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: arrivals.length,
                                itemBuilder: (_, i) => _SmallBookCard(
                                  book: arrivals[i],
                                  onTap: () => _goDetails(context, arrivals[i]),
                                ),
                              ),
                            ),
                          ],

                          // ── Ad slider ──
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: _AdSlider(key: _adKey),
                          ),

                          // ── Trending ──
                          if (trending.isNotEmpty) ...[
                            _SectionHeader(
                              title: context.read<LanguageBloc>().state.t('Trending Now'),
                              onSeeAll: () => context
                                  .findAncestorStateOfType<MainLibraryViewState>()
                                  ?.switchToTab(1),
                            ),
                            SizedBox(
                              height: 165,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: trending.length,
                                itemBuilder: (_, i) => _SmallBookCard(
                                  book: trending[i],
                                  onTap: () => _goDetails(context, trending[i]),
                                ),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 100),
                        ],
                      ),
                    ],
                  ),
                );
              }
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _SmallBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  const _SmallBookCard({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BookCoverImage(path: book.coverImagePath, borderRadius: 10),
            ),
            const SizedBox(height: 6),
            Text(book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text(book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: onSeeAll,
            child: Text(context.read<LanguageBloc>().state.t('See all'),
                style: const TextStyle(color: AppColors.orange)),
          ),
        ],
      ),
    );
  }
}

class _QuickSearchDelegate extends SearchDelegate {
  final List<Book> books;
  _QuickSearchDelegate({required this.books});

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _results(context);

  @override
  Widget buildSuggestions(BuildContext context) => _results(context);

  Widget _results(BuildContext context) {
    final q = query.toLowerCase();
    final res = q.isEmpty
        ? books
        : books
            .where((b) =>
                b.title.toLowerCase().contains(q) ||
                b.author.toLowerCase().contains(q))
            .toList();

    if (q.isEmpty) {
      return Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(context.read<LanguageBloc>().state.t('Search by title or author'),
              style: const TextStyle(color: Colors.grey)),
        ],
      ));
    }
    if (res.isEmpty) {
      return Center(
          child: Text(context.read<LanguageBloc>().state.t('No books found')));
    }
    return ListView.builder(
      itemCount: res.length,
      itemBuilder: (ctx, i) => ListTile(
        leading:
            SizedBox(width: 40, child: BookCoverImage(path: res[i].coverImagePath)),
        title: Text(res[i].title),
        subtitle: Text(res[i].author),
        onTap: () {
          close(ctx, null);
          Navigator.push(
            ctx,
            MaterialPageRoute(builder: (_) => BookDetailsPage(book: res[i])),
          );
        },
      ),
    );
  }
}

// ── Ad Slider (Cube) ──────────────────────────────────────────────────────────
class _AdSlider extends StatefulWidget {
  const _AdSlider({super.key});

  @override
  State<_AdSlider> createState() => _AdSliderState();
}

class _AdSliderState extends State<_AdSlider> {
  List<dynamic> _ads = [];
  bool _loading = true;
  final PageController _pc = PageController();
  int _page = 0;
  double _offset = 0;
  Timer? _refresh, _auto;

  @override
  void initState() {
    super.initState();
    _fetchAds();
    _refresh = Timer.periodic(const Duration(minutes: 30), (_) => _fetchAds());
    _pc.addListener(
        () { if (mounted) setState(() => _offset = _pc.page ?? 0); });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _auto?.cancel();
    _pc.dispose();
    super.dispose();
  }

  void refresh() {
    for (final ad in _ads) {
      final u = AppConfig.resolveUrl(ad['image_path'] as String?);
      if (u.isNotEmpty) CachedNetworkImage.evictFromCache(u);
    }
    _fetchAds();
  }

  void _startAuto() {
    _auto?.cancel();
    _auto = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _ads.isEmpty) return;
      _pc.animateToPage((_page + 1) % _ads.length,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOut);
    });
  }

  Future<void> _fetchAds() async {
    try {
      final r = await DioClient.instance.dio
          .get('/promos/section/A?ts=${DateTime.now().millisecondsSinceEpoch}');
      if (mounted) {
        setState(() {
          _ads = r.data is List ? r.data : [];
          _loading = false;
        });
        _startAuto();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _ads.isEmpty) return const SizedBox.shrink();
    final lang = context.watch<LanguageBloc>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Text(lang.t('Sponsored'),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 1.0)),
        ),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pc,
            itemCount: _ads.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, idx) {
              final ad = _ads[idx];
              final off = idx - _offset;
              final angle = off * (3.14159 / 2);
              final align = off > 0 ? Alignment.centerLeft : Alignment.centerRight;
              final imgUrl = AppConfig.resolveUrl(ad['image_path'] as String?);

              return Transform(
                alignment: align,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(-angle),
                child: GestureDetector(
                  onTap: () async {
                    if (ad['redirect_link'] != null) {
                      final u = Uri.parse(ad['redirect_link']);
                      if (await canLaunchUrl(u)) {
                        await launchUrl(u, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey[300],
                      image: imgUrl.isNotEmpty
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(imgUrl),
                              fit: BoxFit.cover)
                          : null,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6))
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_ads.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.orange : Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}
