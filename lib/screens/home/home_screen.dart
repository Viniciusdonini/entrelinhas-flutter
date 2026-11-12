import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.service});

  final BookService service;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Stream<List<Book>> _booksStream;

  @override
  void initState() {
    super.initState();
    _booksStream = widget.service.watchBooks();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      _booksStream = widget.service.watchBooks();
    }
  }

  void _retry() {
    setState(() => _booksStream = widget.service.watchBooks());
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: AppStrings.homePageTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ReadingHero(),
          const SizedBox(height: AppSpacing.xl),
          StreamBuilder<List<Book>>(
            stream: _booksStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                final error = snapshot.error;
                return AsyncStateView.error(
                  message: error is ServiceException
                      ? error.message
                      : AppStrings.errorMessage,
                  onRetry: _retry,
                );
              }
              if (!snapshot.hasData) {
                return const AsyncStateView.loading();
              }
              return _LibraryOverview(books: snapshot.data!);
            },
          ),
        ],
      ),
    );
  }
}

class _ReadingHero extends StatelessWidget {
  const _ReadingHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.yourLibrary,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.sage,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppStrings.homeTitle,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppStrings.homeSubtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.sage,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: () => context.goNamed(AppRoutes.bookCreate),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.primary,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text(AppStrings.addBook),
                  ),
                ],
              ),
            ),
            if (constraints.maxWidth >= AppSpacing.desktopBreakpoint) ...[
              const SizedBox(width: AppSpacing.xxl),
              const ExcludeSemantics(
                child: Icon(
                  Icons.local_library_outlined,
                  size: AppSpacing.largeIconSize * 2,
                  color: AppColors.sage,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LibraryOverview extends StatelessWidget {
  const _LibraryOverview({required this.books});

  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    final reading = books
        .where((book) => book.status == BookStatus.reading)
        .toList(growable: false);
    final finishedCount = books
        .where((book) => book.status == BookStatus.finished)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _SummaryCard(
                  label: AppStrings.totalBooks,
                  value: books.length,
                  icon: Icons.auto_stories_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SummaryCard(
                  label: AppStrings.readingBooks,
                  value: reading.length,
                  icon: Icons.bookmark_border_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _SummaryCard(
                  label: AppStrings.finishedBooks,
                  value: finishedCount,
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
            ],
          ),
        ),
        if (books.isEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          AsyncStateView.empty(
            action: FilledButton.icon(
              onPressed: () => context.goNamed(AppRoutes.bookCreate),
              icon: const Icon(Icons.add_rounded),
              label: const Text(AppStrings.addBook),
            ),
          ),
        ] else ...[
          if (reading.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const _HomeSectionHeading(
              title: AppStrings.currentlyReading,
              subtitle: AppStrings.currentlyReadingSubtitle,
            ),
            const SizedBox(height: AppSpacing.md),
            BookCollection(books: reading.take(2).toList(growable: false)),
          ],
          const SizedBox(height: AppSpacing.xl),
          const _HomeSectionHeading(
            title: AppStrings.recentBooks,
            subtitle: AppStrings.recentBooksSubtitle,
          ),
          const SizedBox(height: AppSpacing.md),
          BookCollection(books: books.take(4).toList(growable: false)),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => context.goNamed(AppRoutes.books),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text(AppStrings.seeLibrary),
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: AppSpacing.iconSize),
            const SizedBox(height: AppSpacing.sm),
            Text(value.toString(), style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeSectionHeading extends StatelessWidget {
  const _HomeSectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}
