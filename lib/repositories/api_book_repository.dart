import '../core/constants/service_messages.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/book.dart';
import 'book_repository.dart';

class ApiBookRepository implements BookRepository {
  ApiBookRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<Book>> listBooks() async {
    final json = await _client.request('GET', 'books');
    final data = json['data'];
    if (data is! List) {
      throw const ApiException(ServiceMessages.invalidBookData);
    }
    return data.map(_decode).toList(growable: false);
  }

  @override
  Future<Book?> getBook(String id) async {
    try {
      return _decode(
        (await _client.request(
          'GET',
          'books/${Uri.encodeComponent(id)}',
        ))['data'],
      );
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<String> createBook(Book book) async => _decode(
    (await _client.request('POST', 'books', body: _writeData(book)))['data'],
  ).id;

  @override
  Future<void> updateBook(Book book) async {
    await _client.request(
      'PUT',
      'books/${Uri.encodeComponent(book.id)}',
      body: _writeData(book),
    );
  }

  @override
  Future<void> deleteBook(String id) async {
    await _client.request('DELETE', 'books/${Uri.encodeComponent(id)}');
  }

  Book _decode(Object? value) {
    try {
      if (value is! Map<String, dynamic> || value['id'] == null) {
        throw const FormatException();
      }
      return Book.fromMap(id: value['id'].toString(), data: value);
    } on Object {
      throw const ApiException(ServiceMessages.invalidBookData);
    }
  }

  Map<String, dynamic> _writeData(Book book) => Map.of(book.toMap())
    ..remove('createdAt')
    ..remove('updatedAt');
}
