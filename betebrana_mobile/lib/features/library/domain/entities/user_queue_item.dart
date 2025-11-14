class UserQueueItem {
  const UserQueueItem({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.addedAt,
    required this.status,
    this.availableAt,
    this.expiresAt,
    required this.title,
    required this.author,
    this.description,
  });

  final int id;
  final int bookId;
  final int userId;
  final DateTime addedAt;
  final String status; // 'waiting' or 'available'
  final DateTime? availableAt;
  final DateTime? expiresAt;
  final String title;
  final String author;
  final String? description;

  bool get isAvailableForUser => status.toLowerCase() == 'available';

  factory UserQueueItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      final raw = value?.toString();
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    int parseInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

    return UserQueueItem(
      id: parseInt(json['id']),
      bookId: parseInt(json['book_id'] ?? json['bookId']),
      userId: parseInt(json['user_id'] ?? json['userId']),
      addedAt: parseDate(json['added_at'] ?? json['addedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: (json['status'] as String? ?? '').toLowerCase(),
      availableAt: parseDate(json['available_at'] ?? json['availableAt']),
      expiresAt: parseDate(json['expires_at'] ?? json['expiresAt']),
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}

