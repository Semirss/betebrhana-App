import 'dart:async';
import 'package:betebrana_mobile/features/auth/domain/entities/auth_user.dart';
import 'package:betebrana_mobile/features/auth/presentation/bloc/authentication_bloc.dart';
import 'package:betebrana_mobile/features/auth/presentation/bloc/authentication_event.dart';
import 'package:betebrana_mobile/features/auth/presentation/bloc/authentication_state.dart';
import 'package:betebrana_mobile/main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startAutoRefresh();
    // Get current user from AuthBloc
    _currentUser = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user
        : null;
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
        drawer: _buildDrawer(context),
        appBar: AppBar(
          title: const Text('BeteBrana Library'),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              onPressed: _refreshLibrary,
              icon: const Icon(Icons.refresh),
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

              return RefreshIndicator(
                onRefresh: () async {
                  _refreshLibrary();
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return _BookListTile(book: book);
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: books.length,
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
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
              // Navigation will be handled by the root BlocBuilder
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
}
class _BookListTile extends StatelessWidget {
  const _BookListTile({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _BookCover(coverImagePath: book.coverImagePath),
      title: Text(book.title.isEmpty ? 'Untitled' : book.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(book.author.isEmpty ? 'Unknown author' : book.author),
          const SizedBox(height: 2),
          Text(
            _queueSubtitleText(book),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _getQueueStatusColor(context, book),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${book.availableCopies}/${book.totalCopies} available',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (book.queueInfo?.hasReservation ?? false) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Text(
                'RESERVED',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BookDetailsPage(book: book),
          ),
        ).then((_) {
          final libraryBloc = context.read<LibraryBloc>();
          libraryBloc.add(const LibraryRefreshed());
        });
      },
    );
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
}

class _BookCover extends StatelessWidget {
  const _BookCover({this.coverImagePath});

  final String? coverImagePath;

  @override
  Widget build(BuildContext context) {
    if (coverImagePath == null || coverImagePath!.isEmpty) {
      return const Icon(Icons.book, size: 40);
    }

    final url = '${AppConfig.coversBaseUrl}/$coverImagePath';
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 40,
        height: 60,
        fit: BoxFit.cover,
        placeholder: (context, url) => const SizedBox(
          width: 40,
          height: 60,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.book, size: 40),
      ),
    );
  }
}