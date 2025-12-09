import 'package:flutter/material.dart';
import 'package:betebrana_mobile/features/library/data/book_download_service.dart';
import 'package:betebrana_mobile/features/library/domain/entities/book.dart';
import 'package:betebrana_mobile/features/library/presentation/pages/reader_page.dart';
import 'package:betebrana_mobile/core/config/app_config.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DownloadedBooksPage extends StatefulWidget {
  const DownloadedBooksPage({super.key});

  @override
  State<DownloadedBooksPage> createState() => _DownloadedBooksPageState();
}

class _DownloadedBooksPageState extends State<DownloadedBooksPage> {
  final BookDownloadService _downloadService = BookDownloadService();
  late Future<List<Book>> _downloadedBooksFuture;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadDownloadedBooks();
    _downloadService.cleanupExpiredBooks();
    _downloadService.syncWithServerAndCleanup(); 
  }

  Future<void> _loadDownloadedBooks() async {
    setState(() {
      _downloadedBooksFuture = _downloadService.getDownloadedBooks();
    });
  }

  Future<void> _refreshBooks() async {
    setState(() {
      _downloadedBooksFuture = _downloadService.getDownloadedBooks();
    });
  }

  void _showRemoveConfirmationDialog(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Remove Book', style: TextStyle(color: Colors.white)),
        content: Text('Remove "${book.title}" from downloaded books?', 
            style: const TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _removeBook(book);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeBook(Book book) async {
    setState(() {
      _loading = true;
    });

    try {
      final bookId = int.tryParse(book.id);
      if (bookId != null) {
        await _downloadService.deleteBook(bookId);
      }
      
      await _refreshBooks();
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${book.title}" removed'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _openReaderPage(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderPage(
          book: book,
          rentalDueDate: null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Downloaded Books',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshBooks,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : FutureBuilder<List<Book>>(
              future: _downloadedBooksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load downloaded books',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshBooks,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E1E1E),
                          ),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }

                final books = snapshot.data ?? [];

                if (books.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download, size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        const Text(
                          'No downloaded books',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Download books from the Library for offline reading',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // 2-Column Grid Layout
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65, // Similar to library grid
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return _DownloadedBookGridItem(
                      book: book,
                      onRead: () => _openReaderPage(book),
                      onRemove: () => _showRemoveConfirmationDialog(book),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _DownloadedBookGridItem extends StatelessWidget {
  final Book book;
  final VoidCallback onRead;
  final VoidCallback onRemove;

  const _DownloadedBookGridItem({
    required this.book,
    required this.onRead,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRead,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Cover with Action Overlay
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Book Cover
                _BookCoverImage(path: book.coverImagePath, borderRadius: 12),
                
                // Expiry Badge
                if (book.downloadExpiryDate != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildExpiryBadge(book.downloadExpiryDate!),
                  ),
                
                // Action Buttons Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Read Button
                              FloatingActionButton.small(
                                onPressed: onRead,
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                child: const Icon(Icons.play_arrow, size: 20),
                              ),
                              
                              // Remove Button
                              FloatingActionButton.small(
                                onPressed: onRemove,
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                child: const Icon(Icons.delete, size: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Book Title
          Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          
          const SizedBox(height: 2),
          
          // Author
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Container(
          //   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          //   decoration: BoxDecoration(
          //     color: Colors.green.withOpacity(0.1),
          //     borderRadius: BorderRadius.circular(4),
          //     border: Border.all(color: Colors.green),
          //   ),
          //   child: Text(
          //     'DOWNLOADED',
          //     style: TextStyle(
          //       fontSize: 10,
          //       color: Colors.green,
          //       fontWeight: FontWeight.bold,
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildExpiryBadge(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);
    
    Color badgeColor = Colors.green;
    String badgeText = '';
    
    if (difference.isNegative) {
      badgeColor = Colors.red;
      badgeText = 'EXPIRED';
    } else if (difference.inDays <= 1) {
      badgeColor = Colors.orange;
      badgeText = 'SOON';
    } else if (difference.inDays <= 7) {
      badgeColor = Colors.yellow;
      badgeText = '${difference.inDays}d';
    } else {
      badgeColor = Colors.green;
      badgeText = '${difference.inDays}d';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 10,
            color: Colors.black,
          ),
          const SizedBox(width: 2),
          Text(
            badgeText,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
        child: Container(
          color: const Color(0xFF1E1E1E),
          child: const Center(
            child: Icon(
              Icons.book,
              color: Colors.grey,
              size: 40,
            ),
          ),
        ),
      );
    }

    final url = '${AppConfig.coversBaseUrl}/$path'; // Fixed: Use 'path' parameter
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: const Color(0xFF1E1E1E),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: const Color(0xFF1E1E1E),
          child: const Center(
            child: Icon(
              Icons.error_outline,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

// Helper widget for expiry info (keep for reference, but now using badge)
Widget _buildExpiryInfo(DateTime expiryDate) {
  final now = DateTime.now();
  final difference = expiryDate.difference(now);
  
  Color textColor = Colors.green;
  String statusText = '';
  
  if (difference.isNegative) {
    textColor = Colors.red;
    statusText = 'EXPIRED ${difference.inDays.abs()} days ago';
  } else if (difference.inDays <= 1) {
    textColor = Colors.orange;
    if (difference.inHours <= 2) {
      statusText = 'Expires in ${difference.inMinutes} minutes';
    } else {
      statusText = 'Expires in ${difference.inHours} hours';
    }
  } else if (difference.inDays <= 7) {
    statusText = 'Expires in ${difference.inDays} days';
  } else {
    statusText = 'Expires on ${expiryDate.day}/${expiryDate.month}';
  }
  
  return Row(
    children: [
      Icon(
        Icons.access_time,
        size: 14,
        color: textColor,
      ),
      const SizedBox(width: 4),
      Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}