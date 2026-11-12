import 'book_status.dart';

/// A book contains data only: it has no dependency on Flutter or Firebase.
class Book {
  const Book({
    this.id = '',
    required this.title,
    required this.author,
    required this.totalPages,
    this.genre = '',
    this.currentPage = 0,
    this.status = BookStatus.wantToRead,
    this.notes = '',
    this.coverUrl = '',
    this.createdAt,
    this.updatedAt,
  });

  factory Book.fromMap({
    required String id,
    required Map<String, dynamic> data,
  }) {
    return Book(
      id: id,
      title: data['title'] as String,
      author: data['author'] as String,
      totalPages: data['totalPages'] as int,
      genre: data['genre'] as String? ?? '',
      currentPage: data['currentPage'] as int? ?? 0,
      status: BookStatus.values.byName(
        data['status'] as String? ?? BookStatus.wantToRead.name,
      ),
      notes: data['notes'] as String? ?? '',
      coverUrl: data['coverUrl'] as String? ?? '',
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  final String id;
  final String title;
  final String author;
  final int totalPages;
  final String genre;
  final int currentPage;
  final BookStatus status;
  final String notes;
  final String coverUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// JSON-compatible values; the Firestore service translates timestamps.
  Map<String, dynamic> toMap() => {
    'title': title,
    'author': author,
    'totalPages': totalPages,
    'genre': genre,
    'currentPage': currentPage,
    'status': status.name,
    'notes': notes,
    'coverUrl': coverUrl,
    'createdAt': createdAt?.toUtc().toIso8601String(),
    'updatedAt': updatedAt?.toUtc().toIso8601String(),
  };

  Book copyWith({
    String? id,
    String? title,
    String? author,
    int? totalPages,
    String? genre,
    int? currentPage,
    BookStatus? status,
    String? notes,
    String? coverUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      totalPages: totalPages ?? this.totalPages,
      genre: genre ?? this.genre,
      currentPage: currentPage ?? this.currentPage,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      coverUrl: coverUrl ?? this.coverUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    throw const FormatException('Invalid date in book data.');
  }
}
