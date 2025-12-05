import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:betebrana_mobile/core/config/app_config.dart';
import 'package:betebrana_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:betebrana_mobile/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:betebrana_mobile/features/auth/presentation/bloc/authentication_event.dart';
import 'package:betebrana_mobile/features/auth/presentation/bloc/authentication_state.dart';
import 'package:betebrana_mobile/features/library/data/book_repository.dart';
import 'package:betebrana_mobile/features/library/domain/entities/book.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_bloc.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_event.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_state.dart';
import 'package:betebrana_mobile/features/library/presentation/pages/book_details_page.dart';
import 'package:betebrana_mobile/features/library/presentation/pages/downloaded_books_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// --- MAIN ENTRY POINT ---

class MainLibraryPage extends StatelessWidget {
  const MainLibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // We apply a dark theme override here to match the requested UI style
    // You might want to move this to your main.dart Theme config later
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFFE50914), // Netflix-like red accent
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE50914),
          secondary: Colors.white,
          surface: Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF000000), // Pure black for contrast
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      child: RepositoryProvider(
        create: (_) => BookRepository(),
        child: BlocProvider(
          create: (context) => LibraryBloc(context.read<BookRepository>())
            ..add(const LibraryStarted()),
          child: const _MainLibraryView(),
        ),
      ),
    );
  }
}

class _MainLibraryView extends StatefulWidget {
  const _MainLibraryView();

  @override
  State<_MainLibraryView> createState() => _MainLibraryViewState();
}

class _MainLibraryViewState extends State<_MainLibraryView> with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshLibrary();
    }
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) _refreshLibrary();
    });
  }

  void _refreshLibrary() {
    final libraryBloc = context.read<LibraryBloc>();
    if (libraryBloc.state is! LibraryLoading) {
      libraryBloc.add(const LibraryRefreshed());
    }
  }

  // Public method to allow children to switch tabs
  void switchToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _HomeTab(),     // 0: Home (Carousel)
          _LibraryTab(),  // 1: Library (All Books Grid)
          _ProfileTab(),  // 2: Profile (User + Borrowed + Downloads)
          _SettingsTab(), // 3: Settings (Theme)
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.grid_view),
              activeIcon: Icon(Icons.grid_view_rounded),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}

// --- TAB 1: HOME (CAROUSEL & RECOMMENDED) ---

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryBloc, LibraryState>(
      builder: (context, state) {
        if (state is LibraryLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        List<Book> books = [];
        if (state is LibraryLoaded) {
          books = state.books;
        }

        if (books.isEmpty && state is! LibraryLoading) {
          return const Center(child: Text("No books found"));
        }

        // Logic to simulate categories
        final featuredBooks = books.take(5).toList();
        final recommendedBooks = books.length > 5 ? books.sublist(5) : books;
        final trendingBooks = books.reversed.take(6).toList();
        final classicBooks = books.length > 3 ? books.sublist(2, math.min(books.length, 8)) : books;

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 4, 
                  height: 20, 
                  color: Theme.of(context).primaryColor,
                  margin: const EdgeInsets.only(right: 8),
                ),
                const Text(
                  'BeteBrana',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: BookSearchDelegate(books: books),
                );
              },
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  // Switch to Profile Tab (Index 2)
                  context.findAncestorStateOfType<_MainLibraryViewState>()?.switchToTab(2);
                },
                child: _UserAvatarIcon(),
              ),
              const SizedBox(width: 16),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100), // Space for AppBar
                
                // Section Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    "Read today",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 3D Carousel
                SizedBox(
                  height: 400,
                  child: _CoverFlowCarousel(books: featuredBooks),
                ),
                
                const SizedBox(height: 30),

                // Recommended Section
                _buildSectionHeader("Recommended for you", () {}),
                _buildBookList(context, recommendedBooks),

                // Trending Section
                _buildSectionHeader("Trending Now", () {}),
                _buildBookList(context, trendingBooks),

                // Classics Section
                _buildSectionHeader("Classics", () {}),
                _buildBookList(context, classicBooks),
                
                const SizedBox(height: 100), // Bottom padding for nav bar
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton(
            onPressed: onSeeAll, 
            child: const Text("See all")
          ),
        ],
      ),
    );
  }

  Widget _buildBookList(BuildContext context, List<Book> books) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _navigateToDetails(context, book),
                    child: _BookCoverImage(
                      path: book.coverImagePath, 
                      borderRadius: 12
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  book.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigateToDetails(BuildContext context, Book book) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookDetailsPage(book: book)),
    );
  }
}

// --- SEARCH DELEGATE ---

class BookSearchDelegate extends SearchDelegate {
  final List<Book> books;

  BookSearchDelegate({required this.books});

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = books.where((book) {
      final titleLower = book.title.toLowerCase();
      final authorLower = book.author.toLowerCase();
      final queryLower = query.toLowerCase();
      return titleLower.contains(queryLower) || authorLower.contains(queryLower);
    }).toList();

    if (query.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text("Search by title or author", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (results.isEmpty) {
      return const Center(child: Text("No books found"));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final book = results[index];
        return ListTile(
          leading: SizedBox(
            width: 40,
            child: _BookCoverImage(path: book.coverImagePath),
          ),
          title: Text(book.title),
          subtitle: Text(book.author),
          onTap: () {
            close(context, null); // Close search
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => BookDetailsPage(book: book)),
            );
          },
        );
      },
    );
  }
}

// --- CAROUSEL WIDGET (3D EFFECT) ---

class _CoverFlowCarousel extends StatefulWidget {
  final List<Book> books;
  const _CoverFlowCarousel({required this.books});

  @override
  State<_CoverFlowCarousel> createState() => _CoverFlowCarouselState();
}

class _CoverFlowCarouselState extends State<_CoverFlowCarousel> {
  late PageController _controller;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.65, initialPage: 0);
    _controller.addListener(() {
      setState(() {
        _currentPage = _controller.page!;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.books.isEmpty) return const SizedBox();

    return PageView.builder(
      controller: _controller,
      itemCount: widget.books.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        double diff = index - _currentPage;
        final scale = (1 - (diff.abs() * 0.2)).clamp(0.8, 1.0);
        final rotation = diff * -0.3;
        final opacity = (1 - (diff.abs() * 0.5)).clamp(0.4, 1.0);

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002) 
            ..rotateY(rotation), 
          alignment: Alignment.center,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: GestureDetector(
                onTap: () {
                   Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => BookDetailsPage(book: widget.books[index])),
                  );
                },
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: -10,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: _BookCoverImage(
                          path: widget.books[index].coverImagePath,
                          borderRadius: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: diff.abs() < 0.5 ? 1.0 : 0.0,
                      child: Column(
                        children: [
                          Text(
                            widget.books[index].title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                "4.5", 
                                style: TextStyle(color: Colors.green[400], fontWeight: FontWeight.bold),
                              ),
                              Text(
                                " • ${widget.books[index].author}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- TAB 2: LIBRARY (ALL BOOKS GRID) ---

class _LibraryTab extends StatelessWidget {
  const _LibraryTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            onPressed: () => context.read<LibraryBloc>().add(const LibraryRefreshed()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<LibraryBloc, LibraryState>(
        listener: (context, state) {
          if (state is LibraryLoaded && state.hasUpdates) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.updateMessage ?? 'Updated')),
            );
          }
        },
        builder: (context, state) {
          if (state is LibraryLoading) return const Center(child: CircularProgressIndicator());
          
          if (state is LibraryLoaded) {
            final books = state.books;
            if (books.isEmpty) return const Center(child: Text('No books available'));

            // Redesigned: 2 Column Grid
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65, // Aspect ratio to accommodate poster + info
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return _LibraryGridItem(book: book);
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _LibraryGridItem extends StatelessWidget {
  final Book book;
  const _LibraryGridItem({required this.book});

  @override
  Widget build(BuildContext context) {
    final available = '${book.availableCopies}/${book.totalCopies}';
    final isAvailable = book.isAvailable;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BookDetailsPage(book: book)),
        ).then((_) => context.read<LibraryBloc>().add(const LibraryRefreshed()));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _BookCoverImage(path: book.coverImagePath, borderRadius: 12),
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
                      child: const Icon(Icons.check_circle, color: Colors.green, size: 16),
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.copy_rounded,
                size: 12,
                color: isAvailable ? Colors.grey[400] : Colors.red[300],
              ),
              const SizedBox(width: 4),
              Text(
                "$available Available",
                style: TextStyle(
                  color: isAvailable ? Colors.grey[400] : Colors.red[300],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- TAB 3: PROFILE (USER + BORROWED) ---

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<AuthBloc>().state;
    AuthUser? user = (userState is AuthAuthenticated) ? userState.user : null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile Header
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[800],
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.name ?? 'Guest User',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                user?.email ?? 'Sign in to sync your library',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 30),

              // --- New Downloaded Books Navigation ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.download_done_rounded, color: Theme.of(context).primaryColor),
                ),
                title: const Text("Downloaded Books", style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DownloadedBooksPage()),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Borrowed Books Section
              const Divider(height: 30),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Currently Borrowed",
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              BlocBuilder<LibraryBloc, LibraryState>(
                builder: (context, state) {
                  if (state is LibraryLoaded) {
                    final borrowed = state.books.where((b) => b.userHasRental).toList();
                    
                    if (borrowed.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.book_outlined, size: 40, color: Colors.grey),
                            SizedBox(height: 10),
                            Text("No active rentals"),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: borrowed.length,
                      separatorBuilder: (_,__) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: SizedBox(
                            width: 40, 
                            child: _BookCoverImage(path: borrowed[index].coverImagePath)
                          ),
                          title: Text(borrowed[index].title),
                          subtitle: const Text(
                            "Return due: Soon", 
                            style: TextStyle(color: Colors.orange)
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                          onTap: () {
                             Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BookDetailsPage(book: borrowed[index])
                                ),
                             );
                          },
                        );
                      },
                    );
                  }
                  return const CircularProgressIndicator();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- TAB 4: SETTINGS (THEME) ---

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle application theme'),
            trailing: Switch(
              value: true, // Mock value since we forced dark mode in MainLibraryPage
              activeColor: Theme.of(context).primaryColor,
              onChanged: (val) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Theme switching requires root state management")),
                );
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
               context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
          ),
        ],
      ),
    );
  }
}

// --- HELPER WIDGETS ---

class _UserAvatarIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    String initial = 'G';
    if (state is AuthAuthenticated) {
      if (state.user.name.isNotEmpty) initial = state.user.name[0].toUpperCase();
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey[800],
      child: Text(
        initial,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}

class _BookCoverImage extends StatelessWidget {
  final String? path;
  final double borderRadius;

  const _BookCoverImage({this.path, this.borderRadius = 0});

  @override
  Widget build(BuildContext context) {
    if (path == null || path!.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(color: Colors.grey[800], child: const Icon(Icons.book)),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: '${AppConfig.coversBaseUrl}/$path',
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: Colors.grey[900]),
        errorWidget: (_, __, ___) => Container(
          color: Colors.grey[900], 
          child: const Icon(Icons.error_outline)
        ),
      ),
    );
  }
}