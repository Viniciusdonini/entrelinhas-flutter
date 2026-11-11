import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

typedef AppPageBuilder = Widget Function(
  BuildContext context,
  GoRouterState state,
);

/// The composition root supplies pages so core never imports features.
GoRouter createAppRouter({
  required AppPageBuilder homeBuilder,
  required AppPageBuilder booksBuilder,
  required AppPageBuilder createBuilder,
  required AppPageBuilder editBuilder,
  required AppPageBuilder detailsBuilder,
  required AppPageBuilder aboutBuilder,
  required AppPageBuilder errorBuilder,
}) => GoRouter(
  initialLocation: '/',
  errorBuilder: errorBuilder,
  routes: [
    GoRoute(path: '/', name: AppRoutes.home, builder: homeBuilder),
    GoRoute(path: '/biblioteca', name: AppRoutes.books, builder: booksBuilder),
    GoRoute(
      path: '/biblioteca/novo',
      name: AppRoutes.bookCreate,
      builder: createBuilder,
    ),
    GoRoute(
      path: '/biblioteca/:id/editar',
      name: AppRoutes.bookEdit,
      builder: editBuilder,
    ),
    GoRoute(
      path: '/biblioteca/:id',
      name: AppRoutes.bookDetails,
      builder: detailsBuilder,
    ),
    GoRoute(path: '/sobre', name: AppRoutes.about, builder: aboutBuilder),
  ],
);
