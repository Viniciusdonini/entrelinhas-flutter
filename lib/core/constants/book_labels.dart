import '../../models/book_status.dart';

abstract final class BookLabels {
  static String status(BookStatus status) => switch (status) {
    BookStatus.wantToRead => 'Quero ler',
    BookStatus.reading => 'Lendo',
    BookStatus.finished => 'Concluído',
  };
}
