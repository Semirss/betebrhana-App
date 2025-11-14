import 'package:dio/dio.dart';

import 'package:betebrana_mobile/core/network/dio_client.dart';
import 'package:betebrana_mobile/features/library/domain/entities/user_queue_item.dart';

class QueueRepository {
  QueueRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  Future<List<UserQueueItem>> getUserQueue() async {
    final response = await _dio.get('/user/queue');
    final data = response.data;
    if (data is! List) {
      throw Exception('Unexpected queue response format');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map((json) => UserQueueItem.fromJson(json))
        .toList(growable: false);
  }

  Future<QueueJoinResult> joinQueue(int bookId) async {
    final response = await _dio.post(
      '/queue/add',
      data: <String, dynamic>{'bookId': bookId},
    );

    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Empty response from queue/add');
    }

    final success = data['success'] == true;
    final message = data['message']?.toString() ?? 'Joined queue';
    if (!success) {
      throw Exception(message);
    }

    return QueueJoinResult(
      message: message,
      position: _parseInt(data['position']),
      totalInQueue: _parseInt(data['totalInQueue'] ?? data['total_in_queue']),
      availableCopies:
          _parseInt(data['availableCopies'] ?? data['available_copies']),
    );
  }

  Future<void> removeFromQueue(int queueId) async {
    final response = await _dio.delete(
      '/queue/remove',
      data: <String, dynamic>{'queueId': queueId},
    );

    final data = response.data as Map<String, dynamic>?;
    final success = data?['success'] == true;
    if (!success) {
      final message = data?['message']?.toString() ?? 'Failed to leave queue';
      throw Exception(message);
    }
  }

  static int _parseInt(dynamic value) =>
      int.tryParse(value?.toString() ?? '') ?? 0;
}

class QueueJoinResult {
  const QueueJoinResult({
    required this.message,
    required this.position,
    required this.totalInQueue,
    required this.availableCopies,
  });

  final String message;
  final int position;
  final int totalInQueue;
  final int availableCopies;
}

