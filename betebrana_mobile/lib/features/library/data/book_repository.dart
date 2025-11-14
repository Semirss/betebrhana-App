import 'package:dio/dio.dart';

import 'package:betebrana_mobile/core/network/dio_client.dart';
import 'package:betebrana_mobile/features/library/domain/entities/book.dart';

class BookRepository {
  BookRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  Future<List<Book>> getBooks() async {
    final response = await _dio.get('/books');
    final data = response.data;

    List<dynamic> rawList;
    if (data is List) {
      rawList = data;
    } else if (data is Map<String, dynamic> && data['data'] is List) {
      rawList = data['data'] as List<dynamic>;
    } else {
      throw Exception('Unexpected books response format');
    }

    return rawList
        .where((e) => e is Map<String, dynamic>)
        .map((e) => Book.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}

