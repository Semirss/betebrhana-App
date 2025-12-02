import 'package:bloc/bloc.dart';

import 'package:betebrana_mobile/features/library/data/book_repository.dart';
import 'package:betebrana_mobile/features/library/domain/entities/book.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_event.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  LibraryBloc(this._bookRepository) : super(const LibraryInitial()) {
    on<LibraryStarted>(_onStarted);
    on<LibraryRefreshed>(_onRefreshed);
  }

  final BookRepository _bookRepository;
  List<Book>? _previousBooks;

  Future<void> _onStarted(
    LibraryStarted event,
    Emitter<LibraryState> emit,
  ) async {
    await _loadBooks(emit, showLoading: true);
  }

  Future<void> _onRefreshed(
    LibraryRefreshed event,
    Emitter<LibraryState> emit,
  ) async {
    await _loadBooks(emit, showLoading: false);
  }

  Future<void> _loadBooks(
    Emitter<LibraryState> emit, {
    required bool showLoading,
  }) async {
    if (showLoading) {
      emit(const LibraryLoading());
    }
    
    try {
      final books = await _bookRepository.getBooks();
      
      // Check for updates compared to previous state
      final hasUpdates = _checkForUpdates(books);
      final updateMessage = _getUpdateMessage(books);
      
      _previousBooks = books;
      emit(LibraryLoaded(
        books: books,
        hasUpdates: hasUpdates,
        updateMessage: updateMessage,
      ));
    } catch (e) {
      // If refresh fails, maintain current state if we have one
      if (state is LibraryLoaded) {
        final currentState = state as LibraryLoaded;
        emit(LibraryLoaded(
          books: currentState.books,
          hasUpdates: false,
          updateMessage: null,
        ));
      } else {
        emit(LibraryError(e.toString()));
      }
    }
  }

  bool _checkForUpdates(List<Book> newBooks) {
    if (_previousBooks == null) return false;
    
    // Check if books list length changed
    if (newBooks.length != _previousBooks!.length) {
      return true;
    }
    
    // Check if any book's availability or queue status changed
    for (int i = 0; i < newBooks.length; i++) {
      final newBook = newBooks[i];
      final oldBook = _previousBooks![i];
      
      // Check availability changes
      if (newBook.availableCopies != oldBook.availableCopies) {
        return true;
      }
      
      // Check queue info changes
      final newQueueInfo = newBook.queueInfo;
      final oldQueueInfo = oldBook.queueInfo;
      
      if (newQueueInfo == null && oldQueueInfo == null) {
        continue;
      }
      
      if (newQueueInfo == null || oldQueueInfo == null) {
        return true;
      }
      
      if (newQueueInfo.hasReservation != oldQueueInfo.hasReservation ||
          newQueueInfo.userPosition != oldQueueInfo.userPosition ||
          newQueueInfo.totalInQueue != oldQueueInfo.totalInQueue ||
          newQueueInfo.userInQueue != oldQueueInfo.userInQueue) {
        return true;
      }
    }
    
    return false;
  }

  String? _getUpdateMessage(List<Book> newBooks) {
    if (_previousBooks == null) return null;
    
    // Check for specific meaningful updates to show to user
    for (int i = 0; i < newBooks.length; i++) {
      final newBook = newBooks[i];
      final oldBook = _previousBooks![i];
      
      final newQueueInfo = newBook.queueInfo;
      final oldQueueInfo = oldBook.queueInfo;
      
      // Skip if no queue info in either state
      if (newQueueInfo == null || oldQueueInfo == null) {
        continue;
      }
      
      // Book became available for the user
      if (!oldBook.isAvailable && newBook.isAvailable) {
        return '${newBook.title} is now available!';
      }
      
      // User got a reservation
      if (!oldQueueInfo.hasReservation && newQueueInfo.hasReservation) {
        return '${newBook.title} is reserved for you!';
      }
      
      // User lost a reservation
      if (oldQueueInfo.hasReservation && !newQueueInfo.hasReservation) {
        return 'Reservation expired for ${newBook.title}';
      }
      
      // User moved up in queue
      final oldPosition = oldQueueInfo.userPosition;
      final newPosition = newQueueInfo.userPosition;
      if (oldPosition != null && 
          newPosition != null && 
          newPosition < oldPosition) {
        return 'Moved up in queue for ${newBook.title} (position $newPosition)';
      }
      
      // User joined queue
      if (!oldQueueInfo.userInQueue && newQueueInfo.userInQueue) {
        return 'Joined queue for ${newBook.title}';
      }
      
      // User left queue
      if (oldQueueInfo.userInQueue && !newQueueInfo.userInQueue) {
        return 'Left queue for ${newBook.title}';
      }
    }
    
    return null;
  }
}