import 'package:equatable/equatable.dart';

import 'package:betebrana_mobile/features/library/domain/entities/book.dart';

abstract class LibraryState extends Equatable {
  const LibraryState();

  @override
  List<Object?> get props => [];
}

class LibraryInitial extends LibraryState {
  const LibraryInitial();
}

class LibraryLoading extends LibraryState {
  const LibraryLoading();
}

class LibraryLoaded extends LibraryState {
  const LibraryLoaded({
    required this.books,
    this.hasUpdates = false,
    this.updateMessage,
  });

  final List<Book> books;
  final bool hasUpdates;
  final String? updateMessage;

  @override
  List<Object?> get props => [books, hasUpdates, updateMessage];
}

class LibraryError extends LibraryState {
  const LibraryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}