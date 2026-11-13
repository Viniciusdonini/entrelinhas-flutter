import 'dart:async';

import '../core/constants/service_messages.dart';
import '../core/network/api_exception.dart';
import '../core/utils/validators.dart';
import '../models/book.dart';
import '../models/book_status.dart';
import '../repositories/book_repository.dart';
import 'book_service.dart';
import 'service_exception.dart';

/// Reading rules and use cases; the repository owns HTTP and serialization.
class LibraryBookService implements BookService {
  LibraryBookService(this._repository);

  final BookRepository _repository;
  final _changes = StreamController<void>.broadcast();

  @override
  Stream<List<Book>> watchBooks() {
    late StreamController<List<Book>> controller;
    StreamSubscription<void>? changes;
    var stopped = false;
    var generation = 0;

    bool isCurrent(int request) =>
        !stopped && !controller.isClosed && request == generation;

    Future<void> refresh() async {
      final request = ++generation;
      try {
        final books = await _repository.listBooks();
        if (isCurrent(request)) controller.add(books);
      } on ApiException catch (error, stack) {
        if (isCurrent(request)) {
          controller.addError(ServiceException(error.message), stack);
        }
      } on Object catch (_, stack) {
        if (isCurrent(request)) {
          controller.addError(
            const ServiceException(ServiceMessages.operationFailed),
            stack,
          );
        }
      }
    }

    controller = StreamController<List<Book>>(
      onListen: () {
        if (_changes.isClosed) {
          stopped = true;
          unawaited(controller.close());
          return;
        }
        // Subscribe before the first HTTP read so a concurrent write cannot
        // lose its refresh. An older response must not replace a newer one.
        changes = _changes.stream.listen(
          (_) => unawaited(refresh()),
          onDone: () {
            stopped = true;
            generation++;
            unawaited(controller.close());
          },
        );
        unawaited(refresh());
      },
      onCancel: () async {
        stopped = true;
        generation++;
        await changes?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<Book?> getBook(String id) => _execute(() {
    _checkId(id);
    return _repository.getBook(id);
  });

  @override
  Future<String> createBook(Book book) => _execute(() async {
    final id = await _repository.createBook(_normalize(book));
    if (!_changes.isClosed) _changes.add(null);
    return id;
  });

  @override
  Future<void> updateBook(Book book) => _execute(() async {
    _checkId(book.id);
    await _repository.updateBook(_normalize(book));
    if (!_changes.isClosed) _changes.add(null);
  });

  @override
  Future<void> deleteBook(String id) => _execute(() async {
    _checkId(id);
    await _repository.deleteBook(id);
    if (!_changes.isClosed) _changes.add(null);
  });

  Future<T> _execute<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (error) {
      throw ServiceException(error.message);
    }
  }

  Book _normalize(Book book) {
    final result = book.copyWith(
      title: book.title.trim(),
      author: book.author.trim(),
      genre: book.genre.trim(),
      notes: book.notes.trim(),
      coverUrl: book.coverUrl.trim(),
    );
    if (Validators.title(result.title) != null) {
      throw const ServiceException(ServiceMessages.invalidTitle);
    }
    if (Validators.author(result.author) != null) {
      throw const ServiceException(ServiceMessages.invalidAuthor);
    }
    if (Validators.genre(result.genre) != null ||
        Validators.notes(result.notes) != null) {
      throw const ServiceException(ServiceMessages.textTooLong);
    }
    final coverError = Validators.coverUrl(result.coverUrl);
    if (coverError != null) throw ServiceException(coverError);
    if (Validators.totalPages('${result.totalPages}') != null) {
      throw const ServiceException(ServiceMessages.invalidTotalPages);
    }
    if (Validators.currentPage(
          '${result.currentPage}',
          totalPages: result.totalPages,
        ) !=
        null) {
      throw const ServiceException(ServiceMessages.invalidCurrentPage);
    }
    if ((result.status == BookStatus.wantToRead && result.currentPage != 0) ||
        (result.status == BookStatus.finished &&
            result.currentPage != result.totalPages)) {
      throw const ServiceException(ServiceMessages.inconsistentProgress);
    }
    return result;
  }

  void _checkId(String id) {
    if (!RegExp(r'^[1-9][0-9]*$').hasMatch(id)) {
      throw const ServiceException(ServiceMessages.invalidBookId);
    }
  }

  Future<void> dispose() => _changes.close();
}
