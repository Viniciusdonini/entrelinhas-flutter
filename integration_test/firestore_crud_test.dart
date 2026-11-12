import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'package:entrelinhas/app.dart';
import 'package:entrelinhas/core/constants/app_strings.dart';
import 'package:entrelinhas/core/routes/app_routes.dart';
import 'package:entrelinhas/models/book.dart';
import 'package:entrelinhas/models/book_status.dart';
import 'package:entrelinhas/services/firebase_bootstrap.dart';
import 'package:entrelinhas/widgets/app_scaffold.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('CRUD persiste no Firestore Emulator pelo service real', (
    tester,
  ) async {
    const usesEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
    expect(
      usesEmulator,
      isTrue,
      reason: 'Este teste exige --dart-define-from-file=config/emulator.json.',
    );
    if (!usesEmulator) return;

    final service = await FirebaseBootstrap.initialize();
    final suffix = DateTime.now().microsecondsSinceEpoch;
    var bookId = '';

    try {
      bookId = await service.createBook(
        Book(
          title: 'Livro do teste $suffix',
          author: 'Autora de integração',
          totalPages: 240,
          genre: 'Ficção',
          coverUrl: 'https://example.com/capa.jpg',
        ),
      );
      expect(bookId, isNotEmpty);

      final created = await service.getBook(bookId);
      expect(created, isNotNull);
      expect(created!.title, 'Livro do teste $suffix');
      expect(created.author, 'Autora de integração');
      expect(created.totalPages, 240);
      expect(created.currentPage, 0);
      expect(created.status, BookStatus.wantToRead);
      expect(created.createdAt, isNotNull);
      expect(created.coverUrl, 'https://example.com/capa.jpg');

      final changed = service.watchBooks().firstWhere(
        (books) => books.any(
          (book) =>
              book.id == bookId &&
              book.currentPage == 80 &&
              book.coverUrl == 'https://example.com/nova-capa.jpg',
        ),
      );
      await service.updateBook(
        created.copyWith(
          title: 'Livro editado $suffix',
          currentPage: 80,
          status: BookStatus.reading,
          notes: 'Alteração enviada ao back-end.',
          coverUrl: 'https://example.com/nova-capa.jpg',
        ),
      );

      final books = await changed.timeout(const Duration(seconds: 20));
      expect(books.any((book) => book.id == bookId), isTrue);
      final updated = await service.getBook(bookId);
      expect(updated, isNotNull);
      expect(updated!.title, 'Livro editado $suffix');
      expect(updated.currentPage, 80);
      expect(updated.status, BookStatus.reading);
      expect(updated.notes, 'Alteração enviada ao back-end.');
      expect(updated.createdAt, created.createdAt);
      expect(updated.coverUrl, 'https://example.com/nova-capa.jpg');

      await service.updateBook(updated.copyWith(coverUrl: ''));
      final withoutCover = await service.getBook(bookId);
      expect(withoutCover, isNotNull);
      expect(withoutCover!.coverUrl, isEmpty);
      expect(withoutCover.title, updated.title);
      expect(withoutCover.author, updated.author);
      expect(withoutCover.totalPages, updated.totalPages);
      expect(withoutCover.currentPage, updated.currentPage);
      expect(withoutCover.status, updated.status);
      expect(withoutCover.genre, updated.genre);
      expect(withoutCover.notes, updated.notes);
      expect(withoutCover.createdAt, created.createdAt);

      await service.deleteBook(bookId);
      expect(await service.getBook(bookId), isNull);
      bookId = '';
    } finally {
      if (bookId.isNotEmpty) await service.deleteBook(bookId);
    }
  });

  testWidgets('Registra cinco telas com dados reais do Firestore Emulator', (
    tester,
  ) async {
    const usesEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
    expect(usesEmulator, isTrue);
    if (!usesEmulator) return;

    if (!kIsWeb) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(430, 1000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      if (defaultTargetPlatform == TargetPlatform.android) {
        await binding.convertFlutterSurfaceToImage();
      }
    }

    final service = await FirebaseBootstrap.initialize();
    final createdIds = <String>[];
    const examples = [
      Book(
        title: 'A hora da estrela',
        author: 'Clarice Lispector',
        totalPages: 96,
        currentPage: 96,
        status: BookStatus.finished,
        genre: 'Literatura brasileira',
        notes: 'Uma leitura breve que fica com a gente por muito tempo.',
      ),
      Book(
        title: 'O alienista',
        author: 'Machado de Assis',
        totalPages: 88,
        currentPage: 28,
        status: BookStatus.reading,
        genre: 'Literatura brasileira',
        notes: 'Continuar a leitura no fim de semana. Um capítulo de cada vez.',
      ),
      Book(
        title: 'Uma história para amanhã',
        author: 'Ana Martins',
        totalPages: 240,
        genre: 'Romance',
      ),
    ];

    Future<void> openRoute(
      String route, {
      Map<String, String> parameters = const {},
    }) async {
      tester
          .element(find.byType(AppScaffold).first)
          .goNamed(route, pathParameters: parameters);
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 30),
      );
    }

    Future<void> capture(String name) async {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 30),
      );
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot(name);
    }

    try {
      // Fixture data belongs to the test, and is persisted by the real service.
      // The application itself never inserts fixed sample records.
      for (final book in examples) {
        createdIds.add(await service.createBook(book));
      }
      await tester.pumpWidget(App(initialization: Future.value(service)));
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 30),
      );
      expect(find.text(AppStrings.homePageTitle), findsOneWidget);
      expect(find.text('O alienista'), findsWidgets);
      await capture('inicio');

      await openRoute(AppRoutes.books);
      expect(find.text(AppStrings.libraryTitle), findsOneWidget);
      expect(find.text('A hora da estrela'), findsWidgets);
      await capture('biblioteca');

      await openRoute(AppRoutes.bookCreate);
      await tester.enterText(
        find.byKey(const ValueKey('book-title')),
        'O jardim de histórias',
      );
      await tester.enterText(
        find.byKey(const ValueKey('book-author')),
        'Marina Alves',
      );
      await tester.enterText(
        find.byKey(const ValueKey('book-genre')),
        'Romance',
      );
      await tester.enterText(
        find.byKey(const ValueKey('book-total-pages')),
        '224',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await capture('formulario');

      await openRoute(AppRoutes.bookDetails, parameters: {'id': createdIds[1]});
      expect(find.text('O alienista'), findsWidgets);
      await capture('detalhes');

      await openRoute(AppRoutes.about);
      expect(find.text(AppStrings.aboutTitle), findsOneWidget);
      await capture('sobre');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      for (final id in createdIds) {
        await service.deleteBook(id);
      }
    }
  });
}
