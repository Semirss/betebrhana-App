import 'package:flutter_test/flutter_test.dart';

import 'package:betebrana_mobile/features/library/domain/entities/book.dart';

void main() {
  test('Book.fromJson parses minimal fields', () {
    final json = {
      'id': 1,
      'title': 'Test Book',
      'author': 'Author',
      'total_copies': 3,
      'available_copies': 1,
    };

    final book = Book.fromJson(json);

    expect(book.id, '1');
    expect(book.title, 'Test Book');
    expect(book.author, 'Author');
    expect(book.totalCopies, 3);
    expect(book.availableCopies, 1);
    expect(book.isAvailable, isTrue);
  });
}

