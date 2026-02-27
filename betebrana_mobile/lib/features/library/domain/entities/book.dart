class Book {
  final String id;
  final String title;
  final String author;
  final String? description;
  final String? coverImagePath;
  final String? filePath;
  final String? fileType;
  final int totalCopies;
  final int availableCopies;
  final BookQueueInfo? queueInfo;
  final bool userHasRental;
  final DateTime? downloadExpiryDate;
  final DateTime? downloadDate;
  final bool isDownloaded;

  final String? localFilePath;
  final bool isSponsored;
  final List<String> sponsors;
  final List<int> sponsorIds;
  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    this.coverImagePath,
    this.filePath,
    this.fileType,
    this.totalCopies = 0,
    this.availableCopies = 0,
    this.queueInfo,
    this.userHasRental = false,
    this.downloadExpiryDate,
    this.downloadDate,
    this.isDownloaded = false,
    this.localFilePath, 
    this.isSponsored = false,
    this.sponsors = const [],  
    this.sponsorIds = const [],
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    int _readInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

    return Book(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      description: json['description'] as String?,
      coverImagePath:
          (json['cover_image'] as String?) ?? json['cover'] as String?,
      filePath: (json['file_path'] as String?) ?? json['path'] as String?,
      fileType: (json['file_type'] as String?) ?? json['type'] as String?,
      totalCopies:
          _readInt(json['total_copies'] ?? json['totalCopies'] ?? json['copies']),
      availableCopies: _readInt(
        json['available_copies'] ?? json['availableCopies'] ?? json['available'],
      ),
      queueInfo: json['queueInfo'] is Map<String, dynamic>
          ? BookQueueInfo.fromJson(json['queueInfo'] as Map<String, dynamic>)
          : null,
      userHasRental: json['userHasRental'] as bool? ?? false,
      downloadExpiryDate: json['downloadExpiryDate'] != null 
          ? DateTime.parse(json['downloadExpiryDate'])
          : null,
      downloadDate: json['downloadDate'] != null 
          ? DateTime.parse(json['downloadDate'])
          : null,
      isDownloaded: json['isDownloaded'] as bool? ?? false,
      localFilePath: json['localFilePath'] as String?,
      isSponsored: json['isSponsored'] as bool? ?? false,
      sponsors: (json['sponsors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      sponsorIds: intListFromJson(json['sponsor_ids']),
    );
  }

  static List<int> intListFromJson(dynamic json) {
    if (json == null) return const [];
    if (json is List) {
      return json.map((e) => int.tryParse(e.toString()) ?? 0).where((e) => e != 0).toList();
    }
    return const [];
  }

  bool get isAvailable => availableCopies > 0;
}

class BookQueueInfo {
  const BookQueueInfo({
    required this.totalInQueue,
    required this.userPosition,
    required this.isFirstInQueue,
    required this.userInQueue,
    required this.hasReservation,
    required this.effectiveAvailable,
    required this.timeRemaining,
    required this.expiresAt,
    required this.availableAt,
    required this.queueStatus,
    required this.canJoinQueue,
  });

  final int totalInQueue;
  final int userPosition;
  final bool isFirstInQueue;
  final bool userInQueue;
  final bool hasReservation;
  final bool effectiveAvailable;
  final int timeRemaining;
  final DateTime? expiresAt;
  final DateTime? availableAt;
  final String queueStatus;
  final bool canJoinQueue;

  factory BookQueueInfo.fromJson(Map<String, dynamic> json) {
    int readInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

    DateTime? readDate(dynamic value) {
      final raw = value?.toString();
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    return BookQueueInfo(
      totalInQueue: readInt(json['totalInQueue']),
      userPosition: readInt(json['userPosition']),
      isFirstInQueue: json['isFirstInQueue'] == true,
      userInQueue: json['userInQueue'] == true,
      hasReservation: json['hasReservation'] == true,
      effectiveAvailable: json['effectiveAvailable'] == true,
      timeRemaining: readInt(json['timeRemaining']),
      expiresAt: readDate(json['expiresAt']),
      availableAt: readDate(json['availableAt']),
      queueStatus: json['queueStatus'] as String? ?? '',
      canJoinQueue: json['canJoinQueue'] == true,
    );
  }
}

