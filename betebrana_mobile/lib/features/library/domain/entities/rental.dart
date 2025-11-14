class Rental {
  const Rental({
    required this.id,
    required this.bookId,
    required this.userId,
    required this.rentedAt,
    required this.dueDate,
    required this.status,
    required this.title,
    required this.author,
    this.description,
  });

  final int id;
  final int bookId;
  final int userId;
  final DateTime rentedAt;
  final DateTime dueDate;
  final String status; // e.g. 'active', 'returned', etc.
  final String title;
  final String author;
  final String? description;

  bool get isActive => status.toLowerCase() == 'active';

  factory Rental.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      final raw = value?.toString();
      if (raw == null || raw.isEmpty) {
        return DateTime.fromMillisecondsSinceEpoch(0);
      }
      return DateTime.parse(raw);
    }

    int parseInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

    return Rental(
      id: parseInt(json['id']),
      bookId: parseInt(json['book_id'] ?? json['bookId']),
      userId: parseInt(json['user_id'] ?? json['userId']),
      rentedAt: parseDate(json['rented_at'] ?? json['rentedAt']),
      dueDate: parseDate(json['due_date'] ?? json['dueDate']),
      status: (json['status'] as String? ?? '').toLowerCase(),
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}

