import 'package:betebrana_mobile/core/services/language_service.dart';
import 'package:betebrana_mobile/core/theme/app_theme.dart';
import 'package:betebrana_mobile/features/library/domain/entities/book.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_bloc.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_state.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_event.dart';
import 'package:betebrana_mobile/features/library/presentation/pages/book_details_page.dart';
import 'package:betebrana_mobile/widgets/book_cover_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageBloc>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        if (state is! LibraryLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        final books = state.books;
        final q = _query.toLowerCase();
        final results = q.isEmpty
            ? books
            : books.where((b) {
                return b.title.toLowerCase().contains(q) ||
                    b.author.toLowerCase().contains(q);
              }).toList();

        // Extract unique authors for chips (just taking first 5)
        final allAuthors = books.map((b) => b.author).toSet().toList();
        final popularAuthors = allAuthors.take(5).toList();

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
          appBar: AppBar(
            title: Text(lang.t('Search'),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: lang.t('Titles, authors, or topics...'),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            })
                        : null,
                    filled: true,
                    fillColor: isDark ? AppColors.darkCard : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: _query.isEmpty
              ? _buildDefaultState(context, lang, popularAuthors, books)
              : _buildSearchResults(context, lang, results),
        );
      },
    );
  }

  Widget _buildDefaultState(
    BuildContext context,
    LanguageState lang,
    List<String> authors,
    List<Book> books,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (authors.isNotEmpty) ...[
          Text(lang.t('Popular Authors'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: authors.map((a) => ActionChip(
              label: Text(a),
              onPressed: () {
                _searchCtrl.text = a;
                setState(() => _query = a);
              },
            )).toList(),
          ),
          const SizedBox(height: 24),
        ],
        
        Text(lang.t('Explore Complete Library'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('${books.length} ${lang.t('titles available')}',
            style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        
        // Full library grid preview
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.65,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: books.length,
          itemBuilder: (context, index) => _GridBookItem(book: books[index]),
        ),
      ],
    );
  }

  Widget _buildSearchResults(
      BuildContext context, LanguageState lang, List<Book> results) {
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(lang.t('No books matched your search.'),
                style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final b = results[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: SizedBox(
              width: 50,
              height: 70,
              child: BookCoverImage(path: b.coverImagePath, borderRadius: 6)),
          title: Text(b.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(b.author),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BookDetailsPage(book: b)),
            );
          },
        );
      },
    );
  }
}

class _GridBookItem extends StatelessWidget {
  final Book book;
  const _GridBookItem({required this.book});

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageBloc>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAvailable = book.isAvailable;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookDetailsPage(book: book)),
        ).then((_) => context.read<LibraryBloc>().add(LibraryRefreshed()));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                BookCoverImage(path: book.coverImagePath, borderRadius: 12),
                if (book.userHasRental)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Icon(Icons.check_circle,
                          color: Colors.green, size: 16),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext),
          ),
        ],
      ),
    );
  }
}
