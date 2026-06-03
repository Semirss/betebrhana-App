import 'dart:async';
import 'package:betebrana_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:betebrana_mobile/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:betebrana_mobile/features/auth/presentation/bloc/authentication_event.dart';
import 'package:betebrana_mobile/features/auth/presentation/bloc/authentication_state.dart';
import 'package:betebrana_mobile/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:ui';

import 'package:betebrana_mobile/core/config/app_config.dart';
import 'package:betebrana_mobile/features/library/data/book_repository.dart';
import 'package:betebrana_mobile/features/library/domain/entities/book.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_bloc.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_event.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_state.dart';
import 'package:betebrana_mobile/features/library/presentation/pages/book_details_page.dart';
import 'package:betebrana_mobile/features/library/presentation/pages/downloaded_books_page.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (_) => BookRepository(),
      child: BlocProvider(
        create: (context) => LibraryBloc(context.read<BookRepository>())
          ..add(const LibraryStarted()),
        child: const _LibraryView(),
      ),
    );
  }
}

class _LibraryView extends StatefulWidget {
  const _LibraryView();

  @override
  State<_LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<_LibraryView> with WidgetsBindingObserver {
  Timer? _refreshTimer;
  AuthUser? _currentUser;
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startAutoRefresh();
    // Get current user from AuthBloc
    _currentUser = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user
        : null;
    
    // PageController for the carousel
    _pageController = PageController(viewportFraction: 0.65);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pageController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshLibrary();
    }
  }

  @override
  void didPopNext() {
    _refreshLibrary();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _refreshLibrary();
      }
    });
  }

  void _refreshLibrary() {
    final libraryBloc = context.read<LibraryBloc>();
    if (libraryBloc.state is! LibraryLoading) {
      libraryBloc.add(const LibraryRefreshed());
    }
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

  Widget _buildDrawer(BuildContext context) {
    // Get current user
    final authState = context.read<AuthBloc>().state;
    AuthUser? user;
    
    if (authState is AuthAuthenticated) {
      user = authState.user;
    }
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              user?.name ?? 'Guest',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(user?.email ?? 'Not logged in'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.name.isNotEmpty == true 
                  ? user!.name[0].toUpperCase() 
                  : 'G',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.library_books),
            title: const Text('Library'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Downloaded Books'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DownloadedBooksPage(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.pop(context);
              _showLogoutConfirmation(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookCard(Book book, int index, int currentIndex) {
    final coverUrl = book.coverImagePath.isNotEmpty 
        ? AppConfig.resolveUrl(book.coverImagePath)
        : null;

    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = _pageController.page! - index;
          value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
        } else {
          value = index == currentIndex ? 1.0 : 0.85;
        }

        return Center(
          child: SizedBox(
            height: Curves.easeInOut.transform(value) * 350.0,
            width: Curves.easeInOut.transform(value) * 230.0,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          if (index == currentIndex) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BookDetailsPage(book: book),
              ),
            ).then((_) {
              final libraryBloc = context.read<LibraryBloc>();
              libraryBloc.add(const LibraryRefreshed());
            });
          } else {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          _refreshLibrary();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.white,
        drawer: _buildDrawer(context),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(
                Icons.menu,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              onPressed: _refreshLibrary,
              icon: const Icon(
                Icons.refresh,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
              ),
              tooltip: 'Refresh Library',
            ),
          ],
        ),
        body: BlocConsumer<LibraryBloc, LibraryState>(
          listener: (context, state) {
            if (state is LibraryLoaded && state.hasUpdates) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.updateMessage ?? 'Library updated',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is LibraryLoading || state is LibraryInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is LibraryError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent),
                    const SizedBox(height: 8),
                    Text(
                      'Failed to load books',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _refreshLibrary,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is LibraryLoaded) {
              final books = state.books;
              if (books.isEmpty) {
                return const Center(child: Text('No books available'));
              }

              // Ensure _currentIndex is within bounds
              final safeIndex = _currentIndex < books.length ? _currentIndex : 0;
              final currentBook = books[safeIndex];
              final currentCoverUrl = currentBook.coverImagePath.isNotEmpty 
                  ? AppConfig.resolveUrl(currentBook.coverImagePath)
                  : null;

              return Stack(
                children: [
                  // 1. Animated Background
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: MediaQuery.of(context).size.height * 0.65,
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
                                  image: NetworkImage(currentCoverUrl),
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

                  // 2. White Bottom Section
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: MediaQuery.of(context).size.height * 0.45,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                    ),
                  ),

                  // 3. Carousel and Book Details
                  Positioned.fill(
                    child: SafeArea(
                      child: Column(
                        children: [
                          const Spacer(flex: 1),
                          // Carousel
                          SizedBox(
                            height: 380, // Fixed height to accommodate the cards
                            child: PageView.builder(
                              controller: _pageController,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentIndex = index;
                                });
                              },
                              itemCount: books.length,
                              itemBuilder: (context, index) {
                                final book = books[index];
                                return _buildBookCard(book, index, safeIndex);
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Book Details (Title, Author)
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Text(
                                      currentBook.title.isEmpty ? 'Untitled' : currentBook.title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      currentBook.author.isEmpty ? 'Unknown author' : 'By ${currentBook.author}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black54,
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
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}