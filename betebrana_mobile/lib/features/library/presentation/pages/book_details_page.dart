import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:betebrana_mobile/features/library/data/book_download_service.dart';
import 'package:betebrana_mobile/core/config/app_config.dart';
import 'package:betebrana_mobile/features/library/data/queue_repository.dart';
import 'package:betebrana_mobile/features/library/data/rental_repository.dart';
import 'package:betebrana_mobile/features/library/domain/entities/book.dart';
import 'package:betebrana_mobile/features/library/domain/entities/rental.dart';
import 'package:betebrana_mobile/features/library/domain/entities/user_queue_item.dart';
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

  // Selected Sponsor for this session
  int? _selectedSponsorId;
  String? _selectedSponsorName;

  @override
  void initState() {
    super.initState();
    _rentalRepository = RentalRepository();
    _queueRepository = QueueRepository();
    _downloadService = BookDownloadService();
    _connectivity = Connectivity();
    
    // Select a sponsor once
    if (widget.book.isSponsored && widget.book.sponsors.isNotEmpty) {
       final randomIndex = math.Random().nextInt(widget.book.sponsors.length);
       _selectedSponsorName = widget.book.sponsors[randomIndex];
       // Assuming sponsorIds matches the order of sponsors
       if (widget.book.sponsorIds.length > randomIndex) {
           _selectedSponsorId = widget.book.sponsorIds[randomIndex];
       }
    }

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
    if (!widget.book.isSponsored) return false;
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
      if (!widget.book.isSponsored) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This book is not sponsored and cannot be borrowed.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
      }

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
    if (rental == null) return 'Not currently borrowed';
    
    final due = rental.dueDate.toLocal();
    final now = DateTime.now();
    final difference = due.difference(now);
    
    if (difference.isNegative) {
      return 'OVERDUE by ${difference.inDays.abs()} days!';
    } else if (difference.inDays <= 3) {
      return 'Due in ${difference.inDays} days - Return soon!';
    } else {
      final dateString = '${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}';
      return 'borrowed until $dateString (${difference.inDays} days left)';
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
    
    // User has active rental - show borrowed status
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
              'BORROWED',
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

  Widget _buildSponsorBadge() {
    if (!widget.book.isSponsored) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red),
        ),
        child: const Text(
          'NOT SPONSORED',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
        ),
      );
    }
    
    final sponsor = _selectedSponsorName ?? "Anonymous";

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
            const Icon(Icons.star, color: Colors.blue, size: 12),
            const SizedBox(width:4),
            Text(
                'Sponsored by: $sponsor',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
        ]
      )
    );
  }

  Widget _buildKeyInfoBadges() {
    final book = widget.book;
    final badges = <Widget>[];
    
    // Availability badge
    // Availability badge
    badges.add(_buildAvailabilityBadge());
    badges.add(_buildSponsorBadge());
           
  
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges,
    );
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // We keep the theme's surface colors but adopt the layout from the design
    final scaffoldBg = isDark ? const Color(0xFF121212) : const Color(0xFFF2F2F2); // Clean premium background

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Top Section (Gradient + Top Bar + Cover)
            Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                // Top Background Gradient Shape
                Container(
                  height: 380,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark 
                          ? [const Color(0xFF3E2723), const Color(0xFF1E1E1E)] 
                          : [const Color(0xFFFAF2EB), const Color(0xFFE8D6C4)],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                
                // Top Bar
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTopButton(Icons.arrow_back, () => Navigator.pop(context), isDark),
                      Row(
                        children: [
                          if (_loadingStatus || _downloading || _actionInProgress)
                            const Padding(
                              padding: EdgeInsets.only(right: 16.0),
                              child: SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          _buildTopButton(Icons.bookmark, () {}, isDark), // Bookmark placeholder
                        ]
                      ),
                    ],
                  ),
                ),
                
                // Cover Image
                Padding(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 80),
                  child: Hero(
                    tag: 'book_cover_${book.id}',
                    child: Container(
                      height: 280,
                      width: 190,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildCoverImage(book, isDark),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Content below the cover
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    book.title.isEmpty ? 'Untitled' : book.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium!.copyWith(
                      color: isDark ? Colors.white : const Color(0xFF2C4856),
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Author
                  Text(
                    book.author.isEmpty ? 'Unknown author' : book.author,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium!.copyWith(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                  
                  // Star Rating Placeholder
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('4.9', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.grey.shade400 : const Color(0xFF2C4856))),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      const Icon(Icons.star, color: Colors.orange, size: 16),
                      const Icon(Icons.star_half, color: Colors.orange, size: 16),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Metadata Row
                  _buildMetadataBox(isDark),
                  const SizedBox(height: 32),
                  
                  // Description
                  if ((book.description ?? '').isNotEmpty) ...[
                    Text(
                      book.description!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: isDark ? Colors.grey.shade300 : const Color(0xFF4A6B7C),
                        height: 1.6,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                  

                  
                  // Actions
                  _buildActions(isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopButton(IconData icon, VoidCallback onPressed, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.grey.shade800 : Colors.white).withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: isDark ? Colors.white : Colors.black38),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildMetadataBox(bool isDark) {
    if (_loadingStatus) return const SizedBox.shrink();

    String statusStr = 'Available';
    String detailLabel = 'Copies';
    String detailValue = '${widget.book.availableCopies}/${widget.book.totalCopies}';
    
    if (_activeRental != null) {
      statusStr = 'Borrowed';
      detailLabel = 'Until';
      detailValue = _activeRental!.dueDate.toLocal().toString().split(' ')[0];
    } else if (_queueItem != null) {
      statusStr = 'In Queue';
      detailLabel = 'Position';
      detailValue = widget.book.queueInfo?.userPosition.toString() ?? '-';
    } else if (!widget.book.isAvailable) {
      statusStr = 'Unavailable';
      detailLabel = 'Copies';
      detailValue = '0/${widget.book.totalCopies}';
    }

    String sponsorStr = widget.book.isSponsored ? (_selectedSponsorName ?? 'Anonymous') : 'None';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(12),
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildMetaItem('Status', statusStr, isDark),
          Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.15)),
          _buildMetaItem(detailLabel, detailValue, isDark),
          Container(width: 1, height: 30, color: Colors.grey.withOpacity(0.15)),
          _buildMetaItem('Sponsor', sponsorStr, isDark),
        ],
      ),
    );
  }

  Widget _buildMetaItem(String title, String value, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(value, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF2C4856))),
        ],
      ),
    );
  }


  Widget _buildActions(bool isDark) {
    if (_loadingStatus) {
      return const Center(child: CircularProgressIndicator());
    }
    
    List<Widget> secondaryActions = [];
    Widget? primaryAction;

    // Secondary actions:
    if (_activeRental != null) {
      secondaryActions.add(
        _buildSecondaryButton('Return Book', Icons.undo, Colors.redAccent, (!_actionInProgress && !_isOffline) ? _returnCurrentBook : null, isDark)
      );
    }

    if (_canDownload || _isDownloaded) {
      if (_isDownloaded) {
        secondaryActions.add(
          _buildSecondaryButton('Remove Offline', Icons.delete_outline, Colors.redAccent, (!_actionInProgress) ? _removeDownloadedBook : null, isDark)
        );
      } else {
        secondaryActions.add(
          _buildSecondaryButton(_downloading ? 'Downloading...' : 'Download for Offline', _downloading ? Icons.hourglass_bottom : Icons.cloud_download_outlined, isDark ? Colors.white70 : Colors.black87, (!_actionInProgress && !_downloading) ? _downloadCurrentBook : null, isDark)
        );
      }
    }

    // Primary action:
    if (_canRead) {
      primaryAction = _buildPrimaryButton('Start reading', null, (!_actionInProgress) ? () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderPage(
          book: widget.book,
          rentalDueDate: _activeRental?.dueDate,
          sponsorId: _selectedSponsorId,
        )));
      } : null, gradient: const [Color(0xFFFF9A5E), Color(0xFFFF7A3B)]); // Exactly like the image
    } else if (_canRent) {
      final isReserved = widget.book.queueInfo?.hasReservation ?? false;
      primaryAction = _buildPrimaryButton(
        isReserved ? 'BORROW NOW (Reserved!)' : 'Borrow (21 days)', 
        isReserved ? Icons.access_time_filled : null, 
        (!_actionInProgress && !_isOffline) ? _rentCurrentBook : null,
        gradient: isReserved ? [Colors.teal.shade400, Colors.teal.shade700] : const [Color(0xFFFF9A5E), Color(0xFFFF7A3B)],
      );
    } else if (_canJoinQueue) {
      primaryAction = _buildPrimaryButton('Join Queue', null, (!_actionInProgress && !_isOffline) ? _joinQueueForCurrentBook : null, color: Colors.orange.shade400);
    } else if (_canLeaveQueue) {
      primaryAction = _buildPrimaryButton('Leave Queue', null, (!_actionInProgress && !_isOffline) ? _leaveQueueForCurrentBook : null, color: Colors.grey.shade800);
    } else if (_activeRental == null) {
      primaryAction = _buildPrimaryButton('Not Available', null, null, color: Colors.grey.shade300, textColor: Colors.grey.shade500);
    }

    return Column(
      children: [
        if (secondaryActions.isNotEmpty) ...[
          Row(
            children: secondaryActions.asMap().entries.map((entry) {
              int idx = entry.key;
              Widget btn = entry.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: idx == 0 && secondaryActions.length > 1 ? 6.0 : 0,
                    left: idx == 1 && secondaryActions.length > 1 ? 6.0 : 0
                  ),
                  child: btn,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (primaryAction != null) primaryAction,
      ],
    );
  }

  Widget _buildSecondaryButton(String label, IconData icon, Color color, VoidCallback? onPressed, bool isDark) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1),
    );
  }

  Widget _buildPrimaryButton(String label, IconData? icon, VoidCallback? onPressed, {List<Color>? gradient, Color? color, Color textColor = Colors.white}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: gradient != null ? LinearGradient(colors: gradient) : null,
        color: gradient == null ? (color ?? Colors.blue) : null,
        boxShadow: onPressed != null ? [
          BoxShadow(
            color: (gradient?.last ?? color ?? Colors.blue).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: textColor,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon),
              const SizedBox(width: 8),
            ],
            Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
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

    final url = AppConfig.resolveUrl(book.coverImagePath);
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
}