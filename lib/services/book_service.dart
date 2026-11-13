import '../models/book.dart';

/// Screens depend on use cases; repositories implement persistence separately.
abstract class BookService {
  Stream<List<Book>> watchBooks();

  Future<Book?> getBook(String id);

  Future<String> createBook(Book book);

  Future<void> updateBook(Book book);

  Future<void> deleteBook(String id);
}
