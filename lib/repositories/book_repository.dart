import '../models/book.dart';

abstract interface class BookRepository {
  Future<List<Book>> listBooks();
  Future<Book?> getBook(String id);
  Future<String> createBook(Book book);
  Future<void> updateBook(Book book);
  Future<void> deleteBook(String id);
}
