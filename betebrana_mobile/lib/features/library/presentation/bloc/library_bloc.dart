import 'package:bloc/bloc.dart';

import 'package:betebrana_mobile/features/library/data/book_repository.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_event.dart';
import 'package:betebrana_mobile/features/library/presentation/bloc/library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  LibraryBloc(this._bookRepository) : super(const LibraryInitial()) {
    on<LibraryStarted>(_onStarted);
    on<LibraryRefreshed>(_onRefreshed);
  }

  final BookRepository _bookRepository;

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
      emit(LibraryLoaded(books));
    } catch (e) {
      emit(LibraryError(e.toString()));
    }
  }
}

