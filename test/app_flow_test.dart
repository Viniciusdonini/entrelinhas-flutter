import 'dart:async';

import 'package:entrelinhas/app.dart';
import 'package:entrelinhas/core/constants/app_strings.dart';
import 'package:entrelinhas/core/constants/book_labels.dart';
import 'package:entrelinhas/core/theme/app_theme.dart';
import 'package:entrelinhas/models/book.dart';
import 'package:entrelinhas/models/book_status.dart';
import 'package:entrelinhas/screens/books/book_details_screen.dart';
import 'package:entrelinhas/screens/books/book_form_screen.dart';
import 'package:entrelinhas/services/book_service.dart';
import 'package:entrelinhas/services/service_exception.dart';
import 'package:entrelinhas/widgets/book_cover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mobile flow creates, edits and deletes a book', (tester) async {
    final service = _FakeBookService();
    await _startApp(tester, service);

    await _tapVisible(tester, find.text(AppStrings.library));
    expect(find.text(AppStrings.libraryTitle), findsOneWidget);
    expect(find.text(AppStrings.emptyTitle), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _tapVisible(tester, find.text(AppStrings.addBook).first);
    await _enterField(tester, 'book-title', 'A hora da estrela');
    await _enterField(tester, 'book-author', 'Clarice Lispector');
    await _enterField(tester, 'book-genre', 'Literatura brasileira');
    await _enterField(tester, 'book-total-pages', '96');
    await _enterField(tester, 'book-notes', 'Um trecho para guardar.');
    await _enterField(tester, 'book-cover-url', 'https://example.com/capa.jpg');
    await _tapVisible(tester, find.text(AppStrings.saveBook));

    expect(find.byType(BookDetailsScreen), findsOneWidget);
    expect(find.text('A hora da estrela'), findsWidgets);
    expect(service.books, hasLength(1));
    expect(service.books.single.title, 'A hora da estrela');
    expect(service.books.single.status, BookStatus.wantToRead);
    expect(service.books.single.currentPage, 0);
    expect(service.books.single.coverUrl, 'https://example.com/capa.jpg');
    final originalId = service.books.single.id;
    final originalCreatedAt = service.books.single.createdAt;
    expect(tester.takeException(), isNull);

    await _tapVisible(tester, find.text(AppStrings.editBook));
    expect(find.byType(BookFormScreen), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('book-title')))
          .controller!
          .text,
      'A hora da estrela',
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(const ValueKey('book-cover-url')))
          .controller!
          .text,
      'https://example.com/capa.jpg',
    );
    await _enterField(
      tester,
      'book-title',
      'A hora da estrela — edição pessoal',
    );
    await _enterField(
      tester,
      'book-cover-url',
      'https://example.com/nova-capa.jpg',
    );
    await _tapVisible(tester, find.byType(DropdownButtonFormField<BookStatus>));
    await tester.tap(find.text(BookLabels.status(BookStatus.finished)).last);
    await tester.pumpAndSettle();
    await _tapVisible(tester, find.text(AppStrings.saveBook));

    expect(find.byType(BookDetailsScreen), findsOneWidget);
    expect(find.text('A hora da estrela — edição pessoal'), findsWidgets);
    expect(service.books.single.id, originalId);
    expect(service.books.single.createdAt, originalCreatedAt);
    expect(service.books.single.status, BookStatus.finished);
    expect(service.books.single.currentPage, 96);
    expect(service.books.single.coverUrl, 'https://example.com/nova-capa.jpg');
    expect(service.books.single.genre, 'Literatura brasileira');
    expect(service.books.single.notes, 'Um trecho para guardar.');
    expect(find.text(AppStrings.pagesProgress(96, 96)), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _tapVisible(tester, find.text(AppStrings.editBook));
    await _enterField(tester, 'book-cover-url', '');
    await _tapVisible(tester, find.text(AppStrings.saveBook));
    expect(find.byType(BookDetailsScreen), findsOneWidget);
    expect(service.books.single.coverUrl, isEmpty);
    expect(service.books.single.id, originalId);
    expect(service.books.single.createdAt, originalCreatedAt);
    expect(service.books.single.title, 'A hora da estrela — edição pessoal');
    expect(service.books.single.author, 'Clarice Lispector');
    expect(service.books.single.genre, 'Literatura brasileira');
    expect(service.books.single.notes, 'Um trecho para guardar.');
    expect(service.books.single.totalPages, 96);
    expect(service.books.single.currentPage, 96);
    expect(service.books.single.status, BookStatus.finished);
    expect(tester.takeException(), isNull);

    await _tapVisible(tester, find.text(AppStrings.deleteBook));
    expect(find.byType(AlertDialog), findsOneWidget);
    // Opening the confirmation must not delete anything yet.
    expect(service.books, hasLength(1));
    await _tapVisible(tester, find.text(AppStrings.confirmDelete));

    expect(service.books, isEmpty);
    expect(find.text(AppStrings.libraryTitle), findsOneWidget);
    expect(find.text(AppStrings.emptyTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a generated cover when the remote image cannot load', (
    tester,
  ) async {
    const book = Book(
      title: 'Livro com capa indisponível',
      author: 'Autora de teste',
      totalPages: 120,
      coverUrl: 'https://example.com/capa.jpg',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Center(child: BookCover(book))),
      ),
    );
    // Flutter's test HTTP client returns 400; no external image is downloaded.
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_outlined), findsOneWidget);
    expect(find.byType(ErrorWidget), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows initialization and data loading before the empty state', (
    tester,
  ) async {
    _useMobileViewport(tester);
    final initialization = Completer<BookService>();
    final firstSnapshot = Completer<List<Book>>();
    final service = _FakeBookService(firstSnapshot: firstSnapshot.future);
    _disposeAfterTest(tester, service);

    await tester.pumpWidget(App(initialization: initialization.future));
    expect(find.text(AppStrings.setupLoading), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    initialization.complete(service);
    await tester.pump();
    await tester.pump();
    expect(find.text(AppStrings.loading), findsOneWidget);
    expect(find.text(AppStrings.emptyTitle), findsNothing);

    firstSnapshot.complete([]);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.loading), findsNothing);
    expect(find.text(AppStrings.emptyTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('recovers from a data error when the user retries', (
    tester,
  ) async {
    const failureMessage = 'A conexão está temporariamente indisponível.';
    final service = _FakeBookService(
      loadError: const ServiceException(failureMessage),
    );
    await _startApp(tester, service);

    expect(find.text(AppStrings.errorTitle), findsOneWidget);
    expect(find.text(failureMessage), findsOneWidget);
    expect(find.text(AppStrings.emptyTitle), findsNothing);

    service.loadError = null;
    await _tapVisible(tester, find.text(AppStrings.retry));

    expect(find.text(AppStrings.errorTitle), findsNothing);
    expect(find.text(AppStrings.emptyTitle), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'validates required fields and preserves input after save error',
    (tester) async {
      const failureMessage = 'Não foi possível gravar o livro agora.';
      final service = _FakeBookService(
        createError: const ServiceException(failureMessage),
      );
      await _startApp(tester, service);
      await _tapVisible(tester, find.text(AppStrings.addBook).first);

      await _tapVisible(tester, find.text(AppStrings.saveBook));
      expect(find.text(AppStrings.titleRequired), findsOneWidget);
      expect(find.text(AppStrings.authorRequired), findsOneWidget);
      expect(find.text(AppStrings.pagesInvalid), findsOneWidget);
      expect(service.books, isEmpty);

      await _enterField(tester, 'book-title', 'O alienista');
      await _enterField(tester, 'book-author', 'Machado de Assis');
      await _enterField(tester, 'book-total-pages', '88');
      await _tapVisible(tester, find.text(AppStrings.saveBook));

      expect(find.byType(BookFormScreen), findsOneWidget);
      expect(find.text(failureMessage), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const ValueKey('book-title')))
            .controller!
            .text,
        'O alienista',
      );
      expect(service.books, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}

void _useMobileViewport(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void _disposeAfterTest(WidgetTester tester, _FakeBookService service) {
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await service.dispose();
  });
}

Future<void> _startApp(WidgetTester tester, _FakeBookService service) async {
  _useMobileViewport(tester);
  _disposeAfterTest(tester, service);
  await tester.pumpWidget(
    App(initialization: Future<BookService>.value(service)),
  );
  await tester.pumpAndSettle();
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enterField(WidgetTester tester, String key, String value) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pump();
}

/// Only widget tests use this in-memory implementation. Production always uses
/// FirestoreBookService, and its remote CRUD is covered by integration tests.
class _FakeBookService implements BookService {
  _FakeBookService({this.firstSnapshot, this.loadError, this.createError});

  final Future<List<Book>>? firstSnapshot;
  ServiceException? loadError;
  final ServiceException? createError;
  final _records = <String, Book>{};
  final _changes = StreamController<List<Book>>.broadcast();
  int _nextId = 1;

  List<Book> get books => List<Book>.unmodifiable(_records.values);

  @override
  Stream<List<Book>> watchBooks() async* {
    final error = loadError;
    if (error != null) throw error;
    yield firstSnapshot == null ? books : await firstSnapshot!;
    yield* _changes.stream;
  }

  @override
  Future<Book?> getBook(String id) async => _records[id];

  @override
  Future<String> createBook(Book book) async {
    final error = createError;
    if (error != null) throw error;
    final id = 'book-${_nextId++}';
    final now = DateTime.utc(2026, 11, 9, 12);
    _records[id] = book.copyWith(id: id, createdAt: now, updatedAt: now);
    _changes.add(books);
    return id;
  }

  @override
  Future<void> updateBook(Book book) async {
    _records[book.id] = book.copyWith(updatedAt: DateTime.utc(2026, 11, 9, 13));
    _changes.add(books);
  }

  @override
  Future<void> deleteBook(String id) async {
    _records.remove(id);
    _changes.add(books);
  }

  Future<void> dispose() async => _changes.close();
}
