import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/book_labels.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../models/book.dart';
import '../../models/book_status.dart';
import '../../services/book_service.dart';
import '../../services/service_exception.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/async_state_view.dart';
import '../../widgets/book_collection.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key, required this.service});
  final BookService service;
  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  late Stream<List<Book>> _books;
  final _search = TextEditingController();
  BookStatus? _filter;
  @override
  void initState() {
    super.initState();
    _books = widget.service.watchBooks();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _retry() => setState(() => _books = widget.service.watchBooks());
  void _reset() => setState(() {
    _search.clear();
    _filter = null;
  });

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: AppStrings.libraryTitle,
    subtitle: AppStrings.librarySubtitle,
    actions: [
      FilledButton.icon(
        onPressed: () => context.goNamed(AppRoutes.bookCreate),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addBook),
      ),
    ],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: AppStrings.searchHint,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: AppStrings.clearSearch,
                    onPressed: () => setState(_search.clear),
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            ChoiceChip(
              label: const Text(AppStrings.allBooks),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
            for (final status in BookStatus.values)
              ChoiceChip(
                label: Text(BookLabels.status(status)),
                selected: _filter == status,
                onSelected: (_) => setState(() => _filter = status),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        StreamBuilder<List<Book>>(
          stream: _books,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              final error = snapshot.error;
              return AsyncStateView.error(
                message: error is ServiceException ? error.message : null,
                onRetry: _retry,
              );
            }
            if (!snapshot.hasData) return const AsyncStateView.loading();
            final books = snapshot.data!;
            if (books.isEmpty) {
              return AsyncStateView.empty(
                action: FilledButton.icon(
                  onPressed: () => context.goNamed(AppRoutes.bookCreate),
                  icon: const Icon(Icons.add),
                  label: const Text(AppStrings.addBook),
                ),
              );
            }
            final query = _search.text.trim().toLowerCase();
            final filtered = books
                .where(
                  (book) =>
                      (_filter == null || book.status == _filter) &&
                      (book.title.toLowerCase().contains(query) ||
                          book.author.toLowerCase().contains(query)),
                )
                .toList();
            if (filtered.isEmpty) {
              return AsyncStateView.empty(
                title: AppStrings.noResultsTitle,
                message: AppStrings.noResultsMessage,
                action: OutlinedButton(
                  onPressed: _reset,
                  child: const Text(AppStrings.clearFilters),
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.bookCount(filtered.length),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.md),
                BookCollection(books: filtered),
              ],
            );
          },
        ),
      ],
    ),
  );
}
