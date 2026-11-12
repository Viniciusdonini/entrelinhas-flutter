import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_strings.dart';
import 'core/routes/app_router.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'screens/about/about_screen.dart';
import 'screens/books/book_details_screen.dart';
import 'screens/books/book_form_screen.dart';
import 'screens/books/books_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/startup/startup_screen.dart';
import 'services/book_service.dart';
import 'services/firebase_bootstrap.dart';
import 'services/service_exception.dart';
import 'widgets/app_scaffold.dart';
import 'widgets/async_state_view.dart';

class App extends StatefulWidget {
  const App({super.key, required this.initialization});
  final Future<BookService> initialization;
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late Future<BookService> _initialization;
  GoRouter? _router;
  @override
  void initState() {
    super.initState();
    _initialization = widget.initialization;
  }

  @override
  void dispose() {
    _router?.dispose();
    super.dispose();
  }

  void _retry() =>
      setState(() => _initialization = FirebaseBootstrap.initialize());

  GoRouter _createRouter(BookService service) => createAppRouter(
    homeBuilder: (_, _) => HomeScreen(service: service),
    booksBuilder: (_, _) => BooksScreen(service: service),
    createBuilder: (_, _) => BookFormScreen(service: service),
    editBuilder: (_, state) =>
        BookFormScreen(service: service, bookId: state.pathParameters['id']!),
    detailsBuilder: (_, state) => BookDetailsScreen(
      service: service,
      bookId: state.pathParameters['id']!,
    ),
    aboutBuilder: (_, _) => const AboutScreen(),
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
  Widget build(BuildContext context) => FutureBuilder<BookService>(
    future: _initialization,
    builder: (context, snapshot) {
      const delegates = GlobalMaterialLocalizations.delegates;
      const locales = [Locale('pt', 'BR')];
      if (snapshot.hasData) {
        _router ??= _createRouter(snapshot.data!);
        return MaterialApp.router(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          localizationsDelegates: delegates,
          supportedLocales: locales,
          locale: locales.first,
          routerConfig: _router,
        );
      }
      final error = snapshot.error;
      return MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: delegates,
        supportedLocales: locales,
        locale: locales.first,
        home: StartupScreen(
          message: error is ServiceException ? error.message : null,
          onRetry: snapshot.hasError ? _retry : null,
        ),
      );
    },
  );
}
