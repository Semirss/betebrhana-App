import 'dart:async';
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
  Timer? _countdownTimer;

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
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    // Update UI every minute for real-time countdowns
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
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
      // User can rent if:
      // 1. They have an active reservation (status = 'available'), OR
      // 2. Book is available and no one is in queue, OR
      // 3. Book is available and user is first in queue
      return info.hasReservation || 
             (widget.book.isAvailable && (info.totalInQueue == 0 || info.userPosition == 1));
    }
    
    // Fallback: book is available
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
    if (bookId == null) return;

    // Debug logging
    print('Rent button pressed - Book ID: $bookId');
    print('Can rent: $_canRent');
    print('Active rental: $_activeRental');
    print('Book available: ${widget.book.isAvailable}');
    // print('Queue info: ${widget.book.queueInfo?.toJson()}');

    if (!_canRent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot borrow this book at the moment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _actionInProgress = true;
    });

    try {
      final result = await _rentalRepository.rentBook(bookId);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.green,
        ),
      );
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionInProgress = false;
      });
      
      // Handle queue suggestion for unavailable books
      if (e.toString().contains('not available') || 
          e.toString().contains('unavailable') ||
          e.toString().contains('reserved')) {
        _showQueueSuggestionDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to borrow: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showQueueSuggestionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Book Unavailable'),
        content: Text('"${widget.book.title}" is currently unavailable. Would you like to join the queue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _joinQueueForCurrentBook();
            },
            child: const Text('Join Queue'),
          ),
        ],
      ),
    );
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
        const SnackBar(
          content: Text('Book returned successfully'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionInProgress = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to return: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _joinQueueForCurrentBook() async {
    final bookId = int.tryParse(widget.book.id);
    if (bookId == null) return;

    if (!_canJoinQueue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot join queue for this book'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _actionInProgress = true;
    });

    try {
      final result = await _queueRepository.joinQueue(bookId);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.green,
        ),
      );
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionInProgress = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join queue: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
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
        const SnackBar(
          content: Text('Removed from queue'),
          backgroundColor: Colors.green,
        ),
      );
      await _loadStatus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _actionInProgress = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to leave queue: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _rentalStatusText() {
    if (_loadingStatus) return 'Loading your rental status...';
    final rental = _activeRental;
    if (rental == null) return 'Not currently rented';
    
    final due = rental.dueDate.toLocal();
    final now = DateTime.now();
    final difference = due.difference(now);
    
    if (difference.isNegative) {
      return 'OVERDUE by ${difference.inDays.abs()} days!';
    } else if (difference.inDays <= 3) {
      return 'Due in ${difference.inDays} days - Return soon!';
    } else {
      final dateString = '${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}';
      return 'Rented until $dateString (${difference.inDays} days left)';
    }
  }

  Color _rentalStatusColor() {
    final rental = _activeRental;
    if (rental == null) return Colors.grey;
    
    final due = rental.dueDate.toLocal();
    final now = DateTime.now();
    final difference = due.difference(now);
    
    if (difference.isNegative) {
      return Colors.red;
    } else if (difference.inDays <= 3) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String _queueStatusText() {
    final info = widget.book.queueInfo;
    final item = _queueItem;

    if (info == null && item == null) {
      return 'No active queue for this book';
    }

    // User has active reservation (status = 'available')
    if (info != null && info.hasReservation) {
      final expiresAt = info.expiresAt?.toLocal();
      final now = DateTime.now();
      
      if (expiresAt != null) {
        final difference = expiresAt.difference(now);
        if (difference.isNegative) {
          return 'Reservation expired - You have been removed from queue';
        } else {
          final hours = difference.inHours;
          final minutes = difference.inMinutes.remainder(60);
          
          if (hours > 24) {
            final days = hours ~/ 24;
            final remainingHours = hours % 24;
            return 'Available for you! ⏰ $days days ${remainingHours}h to borrow';
          } else if (hours > 0) {
            return 'Available for you! ⏰ ${hours}h ${minutes}m to borrow';
          } else {
            return 'Available for you! ⏰ ${minutes}m to borrow - HURRY!';
          }
        }
      }
      return 'Available for you - Borrow now!';
    }

    // User is in queue but no reservation yet (status = 'waiting')
    if (item != null) {
      final position = info?.userPosition;
      final totalInQueue = info?.totalInQueue ?? 0;
      
      if (position != null && position > 0) {
        if (position == 1) {
          return 'You are first in queue! Waiting for availability...';
        } else {
          return 'In queue: Position $position of $totalInQueue - Waiting...';
        }
      }
      return 'In queue - Waiting for availability';
    }

    // General queue information
    if (info != null && info.totalInQueue > 0) {
      return '${info.totalInQueue} people waiting in queue';
    }

    return 'No active queue for this book';
  }

  Color _queueStatusColor() {
    final info = widget.book.queueInfo;
    
    if (info?.hasReservation ?? false) {
      return Colors.green;
    }
    
    if (_queueItem != null) {
      return Colors.orange;
    }
    
    return Colors.grey;
  }
Widget _buildAvailabilityBadge() {
  final info = widget.book.queueInfo;
  
  // User has active rental - show RENTED status
  if (_activeRental != null) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.library_books, size: 14, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            'RENTED',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
  
  // User has active reservation
  if (info?.hasReservation ?? false) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 14, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            'RESERVED',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
 
  // Book is generally available
  if (widget.book.isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            'AVAILABLE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
      // User is first in queue and book is available
  if (info?.userPosition == 1 && widget.book.isAvailable) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.orange),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule, size: 14, color: Colors.orange),
        const SizedBox(width: 4),
        Text(
          'JOIN QUEUE',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.orange,
          ),
        ),
      ],
    ),
  );
}
    // Book is unavailable - show join queue
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 14, color: Colors.orange),
          const SizedBox(width: 4),
          Text(
            'JOIN QUEUE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
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
            
            // Book header with cover and basic info
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
                      
                      // Availability badge
                      _buildAvailabilityBadge(),
                      const SizedBox(height: 12),
                      
                      // Copies information
                      Text(
                        '${book.availableCopies}/${book.totalCopies} copies available',
                        style: theme.textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Rental status with color coding
                      Text(
                        _rentalStatusText(),
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: _rentalStatusColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Queue status with color coding
                      Text(
                        _queueStatusText(),
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: _queueStatusColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: (!_actionInProgress && _canRent) ? _rentCurrentBook : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (widget.book.queueInfo?.hasReservation ?? false) 
                          ? Colors.green 
                          : Theme.of(context).primaryColor,
                    ),
                    child: Text(
                      (widget.book.queueInfo?.hasReservation ?? false)
                          ? 'BORROW NOW (Reserved!)'
                          : 'Borrow (21 days)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: (widget.book.queueInfo?.hasReservation ?? false)
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
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
            
            // Read button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (!_actionInProgress && _canRead) ? () {
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
            
            // Description
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
      return Container(
        width: 80,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.book, size: 40, color: Colors.grey),
      );
    }

    final url = '${AppConfig.coversBaseUrl}/$coverImagePath';
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 80,
        height: 120,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 80,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 80,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.book, size: 40, color: Colors.grey),
        ),
      ),
    );
  }
}