import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_strings.dart';
import 'core/network/api_client.dart';
import 'core/network/api_config.dart';
import 'core/network/api_exception.dart';
import 'core/routes/app_router.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'repositories/api_auth_repository.dart';
import 'repositories/api_book_repository.dart';
import 'screens/about/about_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/books/book_details_screen.dart';
import 'screens/books/book_form_screen.dart';
import 'screens/books/books_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/startup/startup_screen.dart';
import 'services/auth_service.dart';
import 'services/book_service.dart';
import 'services/library_book_service.dart';
import 'services/service_exception.dart';
import 'widgets/app_scaffold.dart';
import 'widgets/async_state_view.dart';

/// Composition root. Tests may inject use cases without opening a real server.
class App extends StatefulWidget {
  const App({super.key, this.initialization})
    : authService = null,
      bookService = null;

  const App.api({
    super.key,
    required this.authService,
    required this.bookService,
  }) : initialization = null;

  final Future<BookService>? initialization;
  final AuthService? authService;
  final BookService? bookService;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  Future<BookService>? _initialization;
  AuthService? _auth;
  BookService? _books;
  GoRouter? _router;
  String? _configurationError;
  bool _ownsDependencies = false;

  @override
  void initState() {
    super.initState();
    _initialization = widget.initialization;
    if (_initialization == null) _compose();
  }

  void _compose() {
    _configurationError = null;
    try {
      if (widget.authService != null && widget.bookService != null) {
        _auth = widget.authService;
        _books = widget.bookService;
      } else {
        final client = ApiClient(baseUri: ApiConfig.baseUri);
        _auth = AuthService(
          repository: ApiAuthRepository(client),
          client: client,
        );
        _books = LibraryBookService(ApiBookRepository(client));
        _ownsDependencies = true;
      }
      _router = _createRouter(_books!);
    } on ApiException catch (error) {
      _configurationError = error.message;
    }
  }

  @override
  void dispose() {
    _router?.dispose();
    if (_ownsDependencies) {
      _auth?.dispose();
      final books = _books;
      if (books is LibraryBookService) unawaited(books.dispose());
    }
    super.dispose();
  }

  void _retry() => setState(() {
    if (widget.initialization != null) {
      _initialization = widget.initialization;
    } else {
      _compose();
    }
  });

  GoRouter _createRouter(BookService service) => createAppRouter(
    refreshListenable: _auth,
    redirect: _auth == null
        ? null
        : (_, state) {
            final authPage = [
              AppRoutes.loginPath,
              AppRoutes.registerPath,
            ].contains(state.matchedLocation);
            if (!_auth!.isAuthenticated && !authPage) {
              return state.namedLocation(AppRoutes.login);
            }
            if (_auth!.isAuthenticated && authPage) {
              return state.namedLocation(AppRoutes.home);
            }
            return null;
          },
    loginBuilder: _auth == null ? null : (_, _) => LoginScreen(service: _auth!),
    registerBuilder: _auth == null
        ? null
        : (_, _) => RegisterScreen(service: _auth!),
    homeBuilder: (_, _) => HomeScreen(service: service),
    booksBuilder: (_, _) => BooksScreen(service: service),
    createBuilder: (_, _) => BookFormScreen(service: service),
    editBuilder: (_, state) =>
        BookFormScreen(service: service, bookId: state.pathParameters['id']!),
    detailsBuilder: (_, state) => BookDetailsScreen(
      service: service,
      bookId: state.pathParameters['id']!,
    ),
    aboutBuilder: (_, _) => AboutScreen(authService: _auth),
    errorBuilder: (context, _) => AppScaffold(
      title: AppStrings.routeNotFound,
      child: AsyncStateView.empty(
        title: AppStrings.routeNotFound,
        message: AppStrings.routeNotFoundMessage,
        action: FilledButton(
          onPressed: () => context.goNamed(AppRoutes.home),
          child: const Text(AppStrings.goHome),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final initialization = _initialization;
    if (initialization != null) {
      return FutureBuilder<BookService>(
        future: initialization,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _router ??= _createRouter(snapshot.data!);
            return _application(router: _router);
          }
          final error = snapshot.error;
          return _application(
            home: StartupScreen(
              message: error is ServiceException ? error.message : null,
              onRetry: snapshot.hasError ? _retry : null,
            ),
          );
        },
      );
    }
    if (_configurationError != null) {
      return _application(
        home: StartupScreen(message: _configurationError, onRetry: _retry),
      );
    }
    return _application(router: _router);
  }

  Widget _application({GoRouter? router, Widget? home}) {
    const delegates = GlobalMaterialLocalizations.delegates;
    const locales = [Locale('pt', 'BR')];
    if (router != null) {
      return MaterialApp.router(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: delegates,
        supportedLocales: locales,
        locale: locales.first,
        routerConfig: router,
      );
    }
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      localizationsDelegates: delegates,
      supportedLocales: locales,
      locale: locales.first,
      home: home,
    );
  }
}
