import 'package:flutter/material.dart';
import 'package:betebrana_mobile/features/library/data/book_download_service.dart';
import 'package:betebrana_mobile/features/library/domain/entities/book.dart';
import 'package:betebrana_mobile/features/library/presentation/pages/reader_page.dart';
import 'package:betebrana_mobile/core/config/app_config.dart'; // Add this import

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
        title: const Text('Remove Book'),
        content: Text('Remove "${book.title}" from downloaded books?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
        await _downloadService.deleteBook(bookId); // Uncommented and fixed
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

  // Navigate to reader page directly (no need for BookDetailsPage)
  void _openReaderPage(Book book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderPage(
          book: book,
          rentalDueDate: null, // Will use local expiry from downloaded book
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloaded Books'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _refreshBooks,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder<List<Book>>(
              future: _downloadedBooksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        const Text('Failed to load downloaded books'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshBooks,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final books = snapshot.data ?? [];

                if (books.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No downloaded books',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Download books from the Library for offline reading',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                   // Update the list tile builder in DownloadedBooksPage:

return Card(
  margin: const EdgeInsets.only(bottom: 12),
  child: ListTile(
    leading: book.coverImagePath != null
        ? Image.network(
            '${AppConfig.coversBaseUrl}/${book.coverImagePath}',
            width: 40,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 40,
              height: 60,
              color: Colors.grey[200],
              child: const Icon(Icons.book, color: Colors.grey),
            ),
          )
        : Container(
            width: 40,
            height: 60,
            color: Colors.grey[200],
            child: const Icon(Icons.book, color: Colors.grey),
          ),
    title: Text(
      book.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.author,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        
        // Show expiry information
        if (book.downloadExpiryDate != null)
          _buildExpiryInfo(book.downloadExpiryDate!),
        
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.green),
          ),
          child: const Text(
            'DOWNLOADED',
            style: TextStyle(
              fontSize: 10,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showRemoveConfirmationDialog(book),
          tooltip: 'Remove',
        ),
        IconButton(
          icon: const Icon(Icons.menu_book),
          onPressed: () => _openReaderPage(book),
          tooltip: 'Read',
        ),
      ],
    ),
    onTap: () => _openReaderPage(book),
  ),
);
}

                );
              },
            ),
    );
  }
}  Widget _buildExpiryInfo(DateTime expiryDate) {
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

