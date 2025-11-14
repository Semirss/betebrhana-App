import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:betebrana_mobile/core/config/app_config.dart';
import 'package:betebrana_mobile/features/library/data/queue_repository.dart';
import 'package:betebrana_mobile/features/library/data/rental_repository.dart';
import 'package:betebrana_mobile/features/library/domain/entities/book.dart';
import 'package:betebrana_mobile/features/library/domain/entities/rental.dart';
import 'package:betebrana_mobile/features/library/domain/entities/user_queue_item.dart';
import 'reader_page.dart';

class BookDetailsPage extends StatefulWidget {
  const BookDetailsPage({super.key, required this.book});

  final Book book;

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  late final RentalRepository _rentalRepository;
  late final QueueRepository _queueRepository;

  Rental? _activeRental;
  UserQueueItem? _queueItem;
  bool _loadingStatus = true;
  bool _actionInProgress = false;

  @override
  void initState() {
    super.initState();
    _rentalRepository = RentalRepository();
    _queueRepository = QueueRepository();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final bookId = int.tryParse(widget.book.id);
    if (bookId == null) {
      setState(() {
        _loadingStatus = false;
      });
      return;
    }

    setState(() {
      _loadingStatus = true;
    });

    try {
      final rentals = await _rentalRepository.getUserRentals();
      final queue = await _queueRepository.getUserQueue();

      Rental? activeRental;
      for (final rental in rentals) {
        if (rental.bookId == bookId && rental.isActive) {
          activeRental = rental;
          break;
        }
      }

      UserQueueItem? queueItem;
      for (final item in queue) {
        if (item.bookId == bookId) {
          queueItem = item;
          break;
        }
      }

      if (!mounted) return;
      setState(() {
        _activeRental = activeRental;
        _queueItem = queueItem;
        _loadingStatus = false;
        _actionInProgress = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingStatus = false;
        _actionInProgress = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load rental/queue status')),
      );
    }
  }

bool get _canRent {
  if (_activeRental != null) return false;
  
  final info = widget.book.queueInfo;
  if (info != null) {
    // Match web app logic:
    // User can rent if they have reservation OR book is effectively available
    return info.hasReservation || info.effectiveAvailable;
  }
  
  return widget.book.isAvailable;
}
bool get _canReturn => _activeRental != null;

bool get _canJoinQueue {
  if (_activeRental != null || _queueItem != null) return false;
  
  final info = widget.book.queueInfo;
  if (info != null) {
    // User can join queue if:
    // 1. Book is unavailable, OR
    // 2. Book is available but there are people in queue
    return !widget.book.isAvailable || info.totalInQueue > 0;
  }
  
  return !widget.book.isAvailable;
}

bool get _canLeaveQueue => _queueItem != null;

bool get _canRead {
  final hasFile = widget.book.filePath != null && widget.book.filePath!.isNotEmpty;
  return hasFile && _activeRental != null;
}

  Future<void> _rentCurrentBook() async {
    final bookId = int.tryParse(widget.book.id);
    if (bookId == null || !_canRent) return;

    setState(() {
      _actionInProgress = true;
    });

    try {
      final result = await _rentalRepository.rentBook(bookId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionInProgress = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _returnCurrentBook() async {
    final rental = _activeRental;
    final bookId = int.tryParse(widget.book.id);
    if (rental == null || bookId == null) return;

    setState(() {
      _actionInProgress = true;
    });

    try {
      await _rentalRepository.returnBook(rentalId: rental.id, bookId: bookId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book returned successfully')),
      );
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionInProgress = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _joinQueueForCurrentBook() async {
    final bookId = int.tryParse(widget.book.id);
    if (bookId == null || !_canJoinQueue) return;

    setState(() {
      _actionInProgress = true;
    });

    try {
      final result = await _queueRepository.joinQueue(bookId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionInProgress = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _leaveQueueForCurrentBook() async {
    final item = _queueItem;
    if (item == null) return;

    setState(() {
      _actionInProgress = true;
    });

    try {
      await _queueRepository.removeFromQueue(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from queue')),
      );
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionInProgress = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  String _rentalStatusText() {
    if (_loadingStatus) return 'Loading your rental status...';
    final rental = _activeRental;
    if (rental == null) return 'Not currently rented';
    final due = rental.dueDate.toLocal();
    final dateString = '${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}';
    return 'Rented until $dateString';
  }
String _queueStatusText() {
  final info = widget.book.queueInfo;
  final item = _queueItem;

  if (info == null && item == null) {
    return 'No active queue for this book';
  }

  if (info != null && info.hasReservation) {
    final expiresAt = info.expiresAt?.toLocal();
    final expiresString = expiresAt == null
        ? ''
        : ' (expires ${expiresAt.year}-${expiresAt.month.toString().padLeft(2, '0')}-${expiresAt.day.toString().padLeft(2, '0')})';
    return 'Reserved for you$expiresString - You can borrow now!';
  }

  if (item != null) {
    final position = info?.userPosition;
    if (position != null && position > 0) {
      if (position == 1 && widget.book.isAvailable) {
        return 'You are first in queue! Book is available - Borrow now!';
      }
      return 'In queue (position $position)';
    }
    return 'In queue';
  }

  if (info != null && info.totalInQueue > 0) {
    return 'Queue length: ${info.totalInQueue}';
  }

  return 'No active queue for this book';
}

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
  title: Text(book.title.isEmpty ? 'Book details' : book.title),
  actions: [
    IconButton(
      onPressed: _loadStatus,
      icon: const Icon(Icons.refresh),
      tooltip: 'Refresh status',
    ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_actionInProgress || _loadingStatus) ...[
              const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 16),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailsCover(coverImagePath: book.coverImagePath),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title.isEmpty ? 'Untitled' : book.title,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        book.author.isEmpty ? 'Unknown author' : book.author,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${book.availableCopies}/${book.totalCopies} copies available',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _rentalStatusText(),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _queueStatusText(),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        (!_actionInProgress && _canRent) ? _rentCurrentBook : null,
                    child: const Text('Borrow (21 days)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: (!_actionInProgress && _canReturn)
                        ? _returnCurrentBook
                        : null,
                    child: const Text('Return'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: (!_actionInProgress && _canJoinQueue)
                        ? _joinQueueForCurrentBook
                        : null,
                    child: const Text('Join queue'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: (!_actionInProgress && _canLeaveQueue)
                        ? _leaveQueueForCurrentBook
                        : null,
                    child: const Text('Leave queue'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    (!_actionInProgress && _canRead) ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReaderPage(
                            book: book,
                            rentalDueDate: _activeRental?.dueDate,
                          ),
                        ),
                      );
                    } : null,
                icon: const Icon(Icons.menu_book),
                label: const Text('Read'),
              ),
            ),
            const SizedBox(height: 24),
            if ((book.description ?? '').isNotEmpty) ...[
              Text(
                'Description',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                book.description!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailsCover extends StatelessWidget {
  const _DetailsCover({this.coverImagePath});

  final String? coverImagePath;

  @override
  Widget build(BuildContext context) {
    if (coverImagePath == null || coverImagePath!.isEmpty) {
      return const Icon(Icons.book, size: 80);
    }

    final url = '${AppConfig.coversBaseUrl}/$coverImagePath';
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 80,
        height: 120,
        fit: BoxFit.cover,
        placeholder: (context, url) => const SizedBox(
          width: 80,
          height: 120,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => const Icon(Icons.book, size: 80),
      ),
    );
  }
}
