import 'dart:async';

import 'package:entrelinhas/core/network/api_exception.dart';
import 'package:entrelinhas/models/book.dart';
import 'package:entrelinhas/models/book_status.dart';
import 'package:entrelinhas/repositories/book_repository.dart';
import 'package:entrelinhas/services/library_book_service.dart';
import 'package:entrelinhas/services/service_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'service normalizes input and refreshes its stream after CRUD',
    () async {
      final repository = _MemoryRepository();
      final service = LibraryBookService(repository);
      final initial = Completer<void>();
      final created = Completer<void>();
      final changed = Completer<void>();
      final deleted = Completer<void>();
      final snapshots = <List<Book>>[];
      final subscription = service.watchBooks().listen((books) {
        snapshots.add(books);
        if (snapshots.length == 1) initial.complete();
        if (books.isNotEmpty && books.single.title == 'Livro') {
          created.complete();
        }
        if (books.isNotEmpty && books.single.title == 'Editado') {
          changed.complete();
        }
        if (books.isEmpty && snapshots.length > 1) deleted.complete();
      });
      addTearDown(() async {
        await subscription.cancel();
        await service.dispose();
      });
      await initial.future;
      final id = await service.createBook(
        const Book(
          title: ' Livro ',
          author: ' Autora ',
          totalPages: 120,
          notes: ' Notas ',
        ),
      );
      await created.future;
      expect(repository.books.single.author, 'Autora');
      expect(repository.books.single.notes, 'Notas');
      await service.updateBook(
        repository.books.single.copyWith(title: ' Editado '),
      );
      await changed.future;
      await service.deleteBook(id);
      await deleted.future;
      expect(snapshots, hasLength(4));
    },
  );

  test('inconsistent progress is rejected before repository writes', () async {
    final repository = _MemoryRepository();
    final service = LibraryBookService(repository);
    addTearDown(service.dispose);
    await expectLater(
      service.createBook(
        const Book(
          title: 'Livro',
          author: 'Autora',
          totalPages: 120,
          currentPage: 15,
          status: BookStatus.wantToRead,
        ),
      ),
      throwsA(isA<ServiceException>()),
    );
    await expectLater(
      service.createBook(
        const Book(
          title: 'Livro',
          author: 'Autora',
          totalPages: 120,
          coverUrl: 'http://example.test/image.jpg',
        ),
      ),
      throwsA(isA<ServiceException>()),
    );
    expect(repository.books, isEmpty);
  });

  test(
    'a write during the initial read refreshes and ignores older responses',
    () async {
      final repository = _ControlledRepository();
      final service = LibraryBookService(repository);
      final snapshots = <List<Book>>[];
      final receivedLatest = Completer<void>();
      final subscription = service.watchBooks().listen((books) {
        snapshots.add(books);
        receivedLatest.complete();
      });
      addTearDown(() async {
        await subscription.cancel();
        await service.dispose();
      });
      expect(repository.reads, hasLength(1));
      await service.createBook(
        const Book(title: 'Primeira versão', author: 'Autora', totalPages: 120),
      );
      await Future<void>.delayed(Duration.zero);
      expect(repository.reads, hasLength(2));
      final latest = repository.books.single.copyWith(
        title: 'Versão atualizada',
      );
      await service.updateBook(latest);
      await Future<void>.delayed(Duration.zero);
      expect(repository.reads, hasLength(3));
      repository.reads[2].complete([latest]);
      await receivedLatest.future;
      repository.reads[1].complete([latest.copyWith(title: 'Primeira versão')]);
      repository.reads[0].complete([]);
      await Future<void>.delayed(Duration.zero);
      expect(snapshots, hasLength(1));
      expect(snapshots.single.single.title, 'Versão atualizada');
    },
  );

  test(
    'cancelled watchers ignore pending reads and stop requesting refreshes',
    () async {
      final repository = _ControlledRepository();
      final service = LibraryBookService(repository);
      addTearDown(service.dispose);
      final snapshots = <List<Book>>[];
      final subscription = service.watchBooks().listen(snapshots.add);
      expect(repository.reads, hasLength(1));
      await subscription.cancel();
      repository.reads.single.complete([]);
      await service.createBook(
        const Book(title: 'Livro', author: 'Autora', totalPages: 120),
      );
      await Future<void>.delayed(Duration.zero);
      expect(snapshots, isEmpty);
      expect(repository.reads, hasLength(1));
    },
  );

  test('repository errors are translated for screens', () async {
    final service = LibraryBookService(
      _MemoryRepository(failure: const ApiException('Servidor indisponível')),
    );
    addTearDown(service.dispose);
    await expectLater(
      service.watchBooks().first,
      throwsA(
        isA<ServiceException>().having(
          (e) => e.message,
          'message',
          'Servidor indisponível',
        ),
      ),
    );
    await expectLater(
      service.getBook('../invalid'),
      throwsA(isA<ServiceException>()),
    );
  });
}

class _ControlledRepository extends _MemoryRepository {
  final reads = <Completer<List<Book>>>[];

  @override
  Future<List<Book>> listBooks() {
    final read = Completer<List<Book>>();
    reads.add(read);
    return read.future;
  }
}

class _MemoryRepository implements BookRepository {
  _MemoryRepository({this.failure});
  final ApiException? failure;
  final books = <Book>[];

  @override
  Future<List<Book>> listBooks() async {
    if (failure != null) throw failure!;
    return List.of(books);
  }

  @override
  Future<Book?> getBook(String id) async =>
      books.where((book) => book.id == id).firstOrNull;
  @override
  Future<String> createBook(Book book) async {
    final result = book.copyWith(id: '${books.length + 1}');
    books.add(result);
    return result.id;
  }

  @override
  Future<void> updateBook(Book book) async =>
      books[books.indexWhere((current) => current.id == book.id)] = book;
  @override
  Future<void> deleteBook(String id) async =>
      books.removeWhere((book) => book.id == id);
}
