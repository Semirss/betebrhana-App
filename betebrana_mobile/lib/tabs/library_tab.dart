import 'package:betebrana_mobile/core/services/language_service.dart';
import 'package:betebrana_mobile/core/theme/app_theme.dart';
import 'package:betebrana_mobile/features/library/domain/entities/book.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_bloc.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_state.dart';
import 'package:betebrana_mobile/features/library/presentation/pages/book_details_page.dart';
import 'package:betebrana_mobile/features/library/presentation/pages/downloaded_books_page.dart';
import 'package:betebrana_mobile/widgets/book_cover_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:betebrana_mobile/features/library/data/book_download_service.dart';
import 'package:betebrana_mobile/features/library/presentation/pages/reader_page.dart';

class LibraryTab extends StatelessWidget {
  const LibraryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageBloc>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          title: Text(lang.t('My Library'), style: const TextStyle(fontWeight: FontWeight.bold)),
          bottom: TabBar(
            labelColor: AppColors.orange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.orange,
            tabs: [
              Tab(text: lang.t('My Rentals')),
              Tab(text: lang.t('Wishlist')),
              Tab(text: lang.t('Downloads')),
            ],
          ),
        ),
        body: BlocBuilder<LibraryBloc, LibraryState>(
          builder: (context, state) {
            if (state is LibraryLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(lang.t('Loading your library…')),
                  ],
                ),
              );
            }

            if (state is! LibraryLoaded) return const SizedBox();

            final rentals = state.books.where((b) => b.userHasRental).toList();
            final wishlist = state.books.where((b) => b.queueInfo?.userInQueue == true).toList();

            return TabBarView(
              children: [
                _buildList(context, rentals, lang.t('You have no active rentals right now.')),
                _buildList(context, wishlist, lang.t('Your wishlist is empty.')),
                const _DownloadsTabView(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Book> books, String emptyMsg) {
    final lang = context.read<LanguageBloc>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (books.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.library_books_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                emptyMsg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: books.length,
      separatorBuilder: (_, __) => Divider(color: isDark ? Colors.grey[850] : Colors.grey[200], height: 32),
      itemBuilder: (context, index) {
        final b = books[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BookDetailsPage(book: b)),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: BookCoverImage(path: b.coverImagePath, borderRadius: 4), // authentic sharp corners
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      b.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17, 
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      b.author,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (b.userHasRental)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          lang.t('Active Rental'),
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                    else if (b.queueInfo?.userInQueue == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.orange),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          lang.t('In Queue'),
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        );
      },
    );
  }
}

class _DownloadsTabView extends StatefulWidget {
  const _DownloadsTabView();

  @override
  State<_DownloadsTabView> createState() => _DownloadsTabViewState();
}

class _DownloadsTabViewState extends State<_DownloadsTabView> {
  final BookDownloadService _downloadService = BookDownloadService();
  late Future<List<Book>> _downloadedBooksFuture;

  @override
  void initState() {
    super.initState();
    _refreshBooks();
  }

  Future<void> _refreshBooks() async {
    setState(() {
      _downloadedBooksFuture = _downloadService.getDownloadedBooks();
    });
  }

  void _openReaderPage(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ReaderPage(book: book, rentalDueDate: null)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageBloc>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<Book>>(
      future: _downloadedBooksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(lang.t('Failed to load downloads.')));
        }

        final books = snapshot.data ?? [];
        if (books.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.download_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  lang.t('No downloaded books.'),
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: books.length,
          separatorBuilder: (_, __) => Divider(color: isDark ? Colors.grey[850] : Colors.grey[200], height: 32),
          itemBuilder: (context, index) {
            final b = books[index];
            return InkWell(
              onTap: () => _openReaderPage(b),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 120,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: BookCoverImage(path: b.coverImagePath, borderRadius: 4),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          b.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17, 
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          b.author,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _openReaderPage(b),
                              icon: const Icon(Icons.play_arrow, size: 16),
                              label: Text(lang.t('Read')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.white : Colors.black,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                minimumSize: const Size(0, 32),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final bookId = int.tryParse(b.id);
                                if (bookId != null) {
                                  await _downloadService.deleteBook(bookId);
                                  _refreshBooks();
                                }
                              },
                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                              label: Text(lang.t('Remove'), style: const TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                minimumSize: const Size(0, 32),
                                side: const BorderSide(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
