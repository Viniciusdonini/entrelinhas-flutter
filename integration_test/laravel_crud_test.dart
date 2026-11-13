import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';

import 'package:entrelinhas/app.dart';
import 'package:entrelinhas/core/constants/app_strings.dart';
import 'package:entrelinhas/core/network/api_client.dart';
import 'package:entrelinhas/core/network/api_config.dart';
import 'package:entrelinhas/core/routes/app_routes.dart';
import 'package:entrelinhas/models/book.dart';
import 'package:entrelinhas/models/book_status.dart';
import 'package:entrelinhas/repositories/api_auth_repository.dart';
import 'package:entrelinhas/repositories/api_book_repository.dart';
import 'package:entrelinhas/services/auth_service.dart';
import 'package:entrelinhas/services/library_book_service.dart';
import 'package:entrelinhas/widgets/app_scaffold.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late AuthService auth;
  late LibraryBookService service;
  late String email;
  late String password;

  setUpAll(() async {
    final suffix = DateTime.now().microsecondsSinceEpoch;
    email = 'integracao-$suffix@entrelinhas.test';
    password = 'Teste-${suffix}Aa!';
    final client = ApiClient(baseUri: ApiConfig.baseUri);
    auth = AuthService(repository: ApiAuthRepository(client), client: client);
    service = LibraryBookService(ApiBookRepository(client));
    // The account belongs only to this local integration run. No existing
    // user's records are cleared, modified, or used as fixtures.
    await auth.register(
      name: 'Integração Flutter',
      email: email,
      password: password,
      confirmation: password,
    );
  });

  tearDownAll(() async {
    if (auth.isAuthenticated) await auth.logout();
    await service.dispose();
    auth.dispose();
  });

  testWidgets('CRUD persiste na API Laravel pelo repository e service reais', (
    tester,
  ) async {
    var bookId = '';
    try {
      bookId = await service.createBook(
        const Book(
          title: 'Livro de integração',
          author: 'Autora de integração',
          totalPages: 240,
          genre: 'Ficção',
          coverUrl: 'https://example.com/capa.jpg',
        ),
      );
      final created = await service.getBook(bookId);
      expect(created, isNotNull);
      expect(created!.title, 'Livro de integração');
      expect(created.coverUrl, 'https://example.com/capa.jpg');
      expect(created.createdAt, isNotNull);
      final changed = service.watchBooks().firstWhere(
        (books) =>
            books.any((book) => book.id == bookId && book.currentPage == 80),
      );
      await service.updateBook(
        created.copyWith(
          title: 'Livro editado',
          currentPage: 80,
          status: BookStatus.reading,
          notes: 'Persistido no Laravel.',
          coverUrl: 'https://example.com/nova-capa.jpg',
        ),
      );
      await changed.timeout(const Duration(seconds: 20));
      final updated = await service.getBook(bookId);
      expect(updated!.title, 'Livro editado');
      expect(updated.currentPage, 80);
      expect(updated.coverUrl, 'https://example.com/nova-capa.jpg');
      expect(updated.createdAt, created.createdAt);
      await service.updateBook(updated.copyWith(coverUrl: ''));
      final withoutCover = await service.getBook(bookId);
      expect(withoutCover!.coverUrl, isEmpty);
      expect(withoutCover.currentPage, 80);
      expect(withoutCover.createdAt, created.createdAt);
      await service.deleteBook(bookId);
      expect(await service.getBook(bookId), isNull);
      bookId = '';
    } finally {
      if (bookId.isNotEmpty) await service.deleteBook(bookId);
    }
  });

  testWidgets('Captura sete telas com autenticação e dados da API Laravel', (
    tester,
  ) async {
    final createdIds = <String>[];
    Future<void> settle() => tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 30),
    );
    Future<void> capture(String name) async {
      await settle();
      expect(find.text(AppStrings.errorTitle), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await binding.takeScreenshot(name);
    }

    GoRouter router() =>
        GoRouter.of(tester.element(find.byType(AppScaffold).first));
    try {
      await auth.logout();
      await tester.pumpWidget(App.api(authService: auth, bookService: service));
      await capture('login');
      router().goNamed(AppRoutes.register);
      await capture('cadastro_conta');
      await auth.login(email: email, password: password);
      for (final book in const [
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
        ),
        Book(
          title: 'O pequeno príncipe',
          author: 'Antoine de Saint-Exupéry',
          totalPages: 96,
          genre: 'Ficção',
        ),
      ]) {
        createdIds.add(await service.createBook(book));
      }
      router().goNamed(AppRoutes.home);
      await capture('inicio');
      expect(find.text('O alienista'), findsWidgets);
      router().goNamed(AppRoutes.books);
      await capture('biblioteca');
      router().goNamed(AppRoutes.bookCreate);
      await settle();
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
      await capture('formulario');
      router().goNamed(
        AppRoutes.bookDetails,
        pathParameters: {'id': createdIds[1]},
      );
      await capture('detalhes');
      router().goNamed(AppRoutes.about);
      await capture('sobre');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      for (final id in createdIds) {
        await service.deleteBook(id);
      }
    }
  });
}
