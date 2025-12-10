import 'dart:async';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_bloc.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:betebrana_mobile/features/library/data/book_download_service.dart';
import 'package:betebrana_mobile/core/config/app_config.dart';
import 'package:betebrana_mobile/features/library/data/queue_repository.dart';
import 'package:betebrana_mobile/features/library/data/rental_repository.dart';
import 'package:betebrana_mobile/features/library/domain/entities/book.dart';
import 'package:betebrana_mobile/features/library/domain/entities/rental.dart';
import 'package:betebrana_mobile/features/library/domain/entities/user_queue_item.dart';
import 'package:http/http.dart';
import 'reader_page.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class BookDetailsPage extends StatefulWidget {
  const BookDetailsPage({super.key, required this.book});

  final Book book;

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage> {
  late final RentalRepository _rentalRepository;
  late final QueueRepository _queueRepository;
  late final BookDownloadService _downloadService; 
  late final Connectivity _connectivity;
  bool _isOffline = false;
  Timer? _countdownTimer;

  Rental? _activeRental;
  UserQueueItem? _queueItem;
  bool _loadingStatus = true;
  bool _actionInProgress = false;
  bool _isDownloaded = false; 
  bool _downloading = false; 

  // Scroll controller for parallax effect
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

@override
void initState() {
  super.initState();
  _rentalRepository = RentalRepository();
  _queueRepository = QueueRepository();
  _downloadService = BookDownloadService();
  _connectivity = Connectivity();
  
  // Listen to scroll position for parallax effect
  _scrollController.addListener(() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  });
  
  _checkConnectivity(); 
  _loadStatus();
  _checkIfDownloaded();
  _startCountdownTimer();
  _downloadService.syncWithServerAndCleanup();
  
  // Listen for connectivity changes
  _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
    _updateConnectivityStatus(result);
  });
}

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

Future<void> _checkConnectivity() async {
  try {
    final connectivityResult = await _connectivity.checkConnectivity();
    _updateConnectivityStatus(connectivityResult);
  } catch (e) {
    if (mounted) {
      setState(() {
        _isOffline = true;
      });
    }
  }
}

void _updateConnectivityStatus(ConnectivityResult result) {
  if (mounted) {
    setState(() {
      _isOffline = result == ConnectivityResult.none;
    });
  }
}

  Future<void> _checkIfDownloaded() async {
    final bookId = int.tryParse(widget.book.id);
    if (bookId == null) return;
    
    try {
      final downloaded = await _downloadService.isBookDownloaded(bookId);
      if (mounted) {
        setState(() {
          _isDownloaded = downloaded;
        });
      }
    } catch (e) {
      print('Error checking download status: $e');
    }
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

  // Add this method for download
  bool get _canDownload => _activeRental != null;

  Future<void> _downloadCurrentBook() async {
    final bookId = int.tryParse(widget.book.id);
    if (bookId == null || _activeRental == null) return;

    if (!_canDownload) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to rent this book first to download it'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _downloading = true;
    });

    try {
      await _downloadService.downloadAndEncryptBook(
        widget.book,
        _activeRental!.dueDate,
      );
      
      if (!mounted) return;
      
      setState(() {
        _isDownloaded = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${widget.book.title}" downloaded for offline reading'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to download: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
        });
      }
    }
  }

  Future<void> _removeDownloadedBook() async {
    final bookId = int.tryParse(widget.book.id);
    if (bookId == null) return;

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text(
            'Remove Download',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: Text(
            'Remove "${widget.book.title}" from downloaded books?',
            style: TextStyle(color: isDark ? Colors.grey : Colors.black54),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: isDark ? Colors.grey : Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _confirmRemoveDownload(bookId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmRemoveDownload(int bookId) async {
    setState(() {
      _actionInProgress = true;
    });

    try {
      await _downloadService.deleteBook(bookId);
      
      if (!mounted) return;
      
      setState(() {
        _isDownloaded = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${widget.book.title}" removed from downloads'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _actionInProgress = false;
        });
      }
    }
  }

  Future<void> _rentCurrentBook() async {
    final bookId = int.tryParse(widget.book.id);
    if (bookId == null) return;

    // Debug logging
    print('Rent button pressed - Book ID: $bookId');
    print('Can rent: $_canRent');
    print('Active rental: $_activeRental');
    print('Book available: ${widget.book.isAvailable}');

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        title: Text(
          'Book Unavailable',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        content: Text(
          '"${widget.book.title}" is currently unavailable. Would you like to join the queue?',
          style: TextStyle(color: isDark ? Colors.grey : Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? Colors.grey : Colors.black54),
            ),
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
    
    // Remove downloaded book if it exists
    await _downloadService.removeDownloadIfExists(bookId);
    
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Book returned successfully. Download removed if existed.'),
        backgroundColor: Colors.green,
      ),
    );
    
    // IMPORTANT: Force immediate refresh
    // 1. Refresh local status immediately
    await _loadStatus(); 
    await _checkIfDownloaded();
    
    
    
    // 3. If we're in Profile tab context, also trigger a rebuild
    if (mounted) {
      setState(() {});
    }
    
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
    // Show OFFLINE status when there's no internet
    if (_isOffline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              'OFFLINE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
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

  Widget _buildKeyInfoBadges() {
    final book = widget.book;
    final badges = <Widget>[];
    
    // Availability badge
    badges.add(_buildAvailabilityBadge());
    
    // Downloaded badge
    if (_isDownloaded) {
      badges.add(
        Container(
          margin: const EdgeInsets.only(left: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.download_done, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              Text(
                'DOWNLOADED',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Copies information as a badge
    badges.add(
      Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.purple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.purple),
        ),
        child: Text(
          '${book.availableCopies}/${book.totalCopies} copies',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
      ),
    );
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges,
    );
  }

  Widget _buildActionButton() {
    if (_activeRental != null) {
      // Return button when book is rented
      return ElevatedButton.icon(
        onPressed: (!_actionInProgress && !_isOffline) ? _returnCurrentBook : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(176, 172, 88, 9),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 4,
          shadowColor: Colors.red.withOpacity(0.3),
        ),
        icon: const Icon(Icons.undo),
        label: const Text(
          'Return Book',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
    } else if (_canRent) {
      // Rent/borrow button
      return ElevatedButton.icon(
        onPressed: (!_actionInProgress && !_isOffline) ? _rentCurrentBook : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: (widget.book.queueInfo?.hasReservation ?? false) 
              ? Colors.green 
              : Color.fromARGB(255, 245, 152, 45),

          foregroundColor: const Color.fromARGB(255, 0, 0, 0),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 4,
          shadowColor: (widget.book.queueInfo?.hasReservation ?? false)
              ? Colors.green.withOpacity(0.3)
              : Theme.of(context).primaryColor.withOpacity(0.3),
        ),
        icon: (widget.book.queueInfo?.hasReservation ?? false)
            ? const Icon(Icons.access_time_filled)
            : const Icon(Icons.library_add),
        label: Text(
          (widget.book.queueInfo?.hasReservation ?? false)
              ? 'BORROW NOW (Reserved!)'
              : 'Borrow (21 days)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
    } else if (_canJoinQueue) {
      // Join queue button
      return ElevatedButton.icon(
        onPressed: (!_actionInProgress && !_isOffline) ? _joinQueueForCurrentBook : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 4,
          shadowColor: Colors.orange.withOpacity(0.3),
        ),
        icon: const Icon(Icons.schedule),
        label: const Text(
          'Join Queue',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
    } else if (_canLeaveQueue) {
      // Leave queue button
      return ElevatedButton.icon(
        onPressed: (!_actionInProgress && !_isOffline) ? _leaveQueueForCurrentBook : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade700,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 4,
          shadowColor: Colors.grey.withOpacity(0.3),
        ),
        icon: const Icon(Icons.cancel),
        label: const Text(
          'Leave Queue',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
    } else {
      // Disabled state
      return ElevatedButton.icon(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade800,
          foregroundColor: Colors.grey.shade400,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        icon: const Icon(Icons.block),
        label: const Text(
          'Not Available',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      );
    }
  }

  Widget _buildSecondaryActions() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        // Download/Remove download button
        SizedBox(
          width: double.infinity,
          child: _isDownloaded
              ? ElevatedButton.icon(
                  onPressed: (!_actionInProgress) ? _removeDownloadedBook : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                      side: BorderSide(color: Colors.red.withOpacity(0.3)),
                    ),
                  ),
                  icon: const Icon(Icons.delete),
                  label: const Text('Remove Download'),
                )
              : ElevatedButton.icon(
                  onPressed: (!_actionInProgress && !_downloading && _canDownload) 
                      ? _downloadCurrentBook 
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canDownload 
                        ? (isDark ? Colors.white : Colors.black87)
                        : Colors.grey.withOpacity(0.1),
                    foregroundColor: _canDownload 
                        ? (isDark ? Colors.black : Colors.white)
                        : Colors.grey,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                      side: BorderSide(
                        color: _canDownload 
                            ? Theme.of(context).primaryColor.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                  ),
                  icon: _downloading 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        )
                      : const Icon(Icons.download),
                  label: Text(_downloading ? 'Downloading...' : 'Download for Offline'),
                ),
        ),
        const SizedBox(height: 12),
        
        // Read button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (!_actionInProgress && _canRead) ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReaderPage(
                    book: widget.book,
                    rentalDueDate: _activeRental?.dueDate,
                  ),
                ),
              );
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(211, 241, 126, 19).withOpacity(0.5),
              foregroundColor: _canRead ? const Color.fromARGB(255, 255, 255, 255) : const Color.fromARGB(255, 231, 227, 224),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(
                  color: _canRead 
                      ? Colors.blue.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
            icon: const Icon(Icons.menu_book),
            label: const Text('Read Book'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color.fromARGB(255, 248, 222, 173),
      body: Stack(
        children: [
          // Custom Scroll View for immersive header
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Parallax header with book cover
              SliverAppBar(
                expandedHeight: 350,
                collapsedHeight: 0,
                toolbarHeight: 0,
                pinned: false,
                floating: false,
                snap: false,
                stretch: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Book cover with parallax effect
                      Transform.translate(
                        offset: Offset(0, -_scrollOffset * 0.3),
                        child: _buildCoverImage(book, isDark),
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              isDark ? Colors.black.withOpacity(0.5) : const Color.fromARGB(255, 248, 222, 173).withOpacity(0.7),
                              isDark ? Colors.black : const Color.fromARGB(255, 248, 222, 173),
                            ],
                            stops: const [0.4, 0.8, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Floating content card
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Book title and author
                        Text(
                          book.title.isEmpty ? 'Untitled' : book.title,
                          style: theme.textTheme.headlineMedium!.copyWith(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Text(
                          book.author.isEmpty ? 'Unknown author' : book.author,
                          style: theme.textTheme.titleMedium!.copyWith(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Key info badges
                        _buildKeyInfoBadges(),
                        const SizedBox(height: 24),
                        
                        // Status indicators
                        if (_rentalStatusText().isNotEmpty)
                          _buildStatusIndicator(
                            Icons.library_books,
                            _rentalStatusText(),
                            _rentalStatusColor(),
                          ),
                        
                        if (_queueStatusText().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _buildStatusIndicator(
                              Icons.groups,
                              _queueStatusText(),
                              _queueStatusColor(),
                            ),
                          ),
                        
                        const SizedBox(height: 32),
                        
                        // Secondary actions
                        _buildSecondaryActions(),
                        
                        const SizedBox(height: 32),
                        
                        // Description section
                        if ((book.description ?? '').isNotEmpty) ...[
                          Text(
                            'About this book',
                            style: theme.textTheme.titleLarge!.copyWith(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            book.description!,
                            style: theme.textTheme.bodyLarge!.copyWith(
                              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                              height: 1.6,
                            ),
                          ),
                        ],
                        
                        // Bottom padding for floating action button
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // App bar with back button
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back, 
                        color: isDark ? Colors.white : Colors.black
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  if (_loadingStatus || _downloading || _actionInProgress)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.black : Colors.white).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.refresh, 
                        color: isDark ? Colors.white : Colors.black
                      ),
                      onPressed: _loadStatus,
                      tooltip: 'Refresh status',
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Floating action button at bottom
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: _buildActionButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(Book book, bool isDark) {
    if (book.coverImagePath == null || book.coverImagePath!.isEmpty) {
      return Container(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
        child: Center(
          child: Icon(
            Icons.book,
            size: 100,
            color: isDark ? Colors.grey : Colors.grey[600],
          ),
        ),
      );
    }

    final url = '${AppConfig.coversBaseUrl}/${book.coverImagePath}';
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
        child: Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
        child: Center(
          child: Icon(
            Icons.book,
            size: 100,
            color: isDark ? Colors.grey : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}