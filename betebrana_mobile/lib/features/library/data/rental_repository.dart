import 'package:dio/dio.dart';

import 'package:betebrana_mobile/core/network/dio_client.dart';
import 'package:betebrana_mobile/features/library/domain/entities/rental.dart';

class RentalRepository {
  RentalRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  Future<List<Rental>> getUserRentals() async {
    final response = await _dio.get('/user/rentals');
    final data = response.data;
    if (data is! List) {
      throw Exception('Unexpected rentals response format');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => Rental.fromJson(json))
        .toList(growable: false);
  }

  Future<RentResult> rentBook(int bookId) async {
    final response = await _dio.post(
      '/books/rent',
      data: <String, dynamic>{'bookId': bookId},
    );

    final data = response.data as Map<String, dynamic>?;
    final message = data?['message']?.toString() ?? 'Book rented successfully';
    final dueRaw = data?['dueDate']?.toString();
    final dueDate = dueRaw != null && dueRaw.isNotEmpty
        ? DateTime.tryParse(dueRaw)
        : null;

    final success = data?['success'] == true;
    if (!success) {
      throw Exception(message);
    }

    return RentResult(message: message, dueDate: dueDate);
  }

  Future<void> returnBook({required int rentalId, required int bookId}) async {
    final response = await _dio.post(
      '/books/return',
      data: <String, dynamic>{
        'rentalId': rentalId,
        'bookId': bookId,
      },
    );

    final data = response.data as Map<String, dynamic>?;
    final success = data?['success'] == true;
    if (!success) {
      final message = data?['message']?.toString() ?? 'Failed to return book';
      throw Exception(message);
    }
  }
}

class RentResult {
  const RentResult({required this.message, this.dueDate});

  final String message;
  final DateTime? dueDate;
}

