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

  void refresh() {
    _adKey.currentState?.refresh();
    DefaultCacheManager().emptyCache();
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    context.read<LibraryBloc>().add(LibraryRefreshed());
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageBloc>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        List<Book> books = state is LibraryLoaded ? state.books : [];
        final featured = books.isNotEmpty ? books.first : null;
        final arrivals = books.length > 1 ? books.sublist(1, math.min(books.length, 10)) : [];
        final trending = books.reversed.take(5).toList();

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // ── Header bar ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          lang.t('Discover'),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.darkText : AppColors.lightText,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.search,
                              color: isDark ? AppColors.darkText : AppColors.lightText),
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

                if (state is LibraryLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  // ── Featured ──
                  if (featured != null) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Text(
                          lang.t('Featured'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _FeaturedCard(book: featured, lang: lang),
                      ),
                    ),
                  ],

                  // ── New Arrivals ──
                  if (arrivals.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: lang.t('New Arrivals'),
                        onSeeAll: () => context
                            .findAncestorStateOfType<MainLibraryViewState>()
                            ?.switchToTab(1),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
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
                    ),
                  ],

                  // ── Ad slider ──
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _AdSlider(key: _adKey),
                    ),
                  ),

                  // ── Trending ──
                  if (trending.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: _SectionHeader(
                        title: lang.t('Trending Now'),
                        onSeeAll: () => context
                            .findAncestorStateOfType<MainLibraryViewState>()
                            ?.switchToTab(1),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
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
                    ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _goDetails(BuildContext context, Book book) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailsPage(book: book)));
  }
}

class _FeaturedCard extends StatelessWidget {
  final Book book;
  final LanguageState lang;
  const _FeaturedCard({required this.book, required this.lang});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BookDetailsPage(book: book)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: BookCoverImage(path: book.coverImagePath, borderRadius: 16),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${book.title} (${book.author})',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(book.author,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade500)),
          const SizedBox(height: 12),
          SizedBox(
            width: 160,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookDetailsPage(book: book)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(lang.t('Open Now'),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
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

// Quick search delegate reused from existing code
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
