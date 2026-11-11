import '../models/book.dart';

/// Screens depend on this contract rather than on the Firestore SDK.
abstract class BookService {
  Stream<List<Book>> watchBooks();

  Future<Book?> getBook(String id);

  Future<String> createBook(Book book);

  Future<void> updateBook(Book book);

  Future<void> deleteBook(String id);
}
