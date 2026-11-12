import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/book_labels.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/book.dart';
import '../../services/book_service.dart';
import '../../services/service_exception.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/async_state_view.dart';
import '../../widgets/book_cover.dart';
import '../../widgets/status_badge.dart';

class BookDetailsScreen extends StatefulWidget {
  const BookDetailsScreen({
    super.key,
    required this.service,
    required this.bookId,
  });

  final BookService service;
  final String bookId;

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  late Future<Book?> _bookFuture;
  bool _deleting = false;
  String? _deleteError;

  @override
  void initState() {
    super.initState();
    _bookFuture = widget.service.getBook(widget.bookId);
  }

  @override
  void didUpdateWidget(covariant BookDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bookId != oldWidget.bookId ||
        widget.service != oldWidget.service) {
      _bookFuture = widget.service.getBook(widget.bookId);
      _deleteError = null;
    }
  }

  void _retry() {
    setState(() {
      _bookFuture = widget.service.getBook(widget.bookId);
    });
  }

  Future<void> _delete(Book book) async {
    if (_deleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded),
        title: const Text(AppStrings.deleteBookTitle),
        content: Text(AppStrings.deleteBookMessage(book.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(AppStrings.confirmDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _deleting = true;
      _deleteError = null;
    });
    try {
      await widget.service.deleteBook(book.id);
      if (!mounted) return;
      context.goNamed(AppRoutes.books);
    } on ServiceException catch (error) {
      if (mounted) setState(() => _deleteError = error.message);
    } catch (_) {
      if (mounted) setState(() => _deleteError = AppStrings.deleteBookError);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: AppStrings.bookDetailsTitle,
      subtitle: AppStrings.detailsSubtitle,
      actions: [
        TextButton.icon(
          onPressed: _deleting ? null : () => context.goNamed(AppRoutes.books),
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text(AppStrings.backToLibrary),
        ),
      ],
      child: FutureBuilder<Book?>(
        future: _bookFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AsyncStateView.loading();
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return AsyncStateView.error(
              message: error is ServiceException
                  ? error.message
                  : AppStrings.loadBookError,
              onRetry: _retry,
            );
          }
          final book = snapshot.data;
          if (book == null) {
            return AsyncStateView.empty(
              title: AppStrings.bookNotFoundTitle,
              message: AppStrings.bookNotFoundMessage,
              action: FilledButton(
                onPressed: () => context.goNamed(AppRoutes.books),
                child: const Text(AppStrings.backToLibrary),
              ),
            );
          }
          return _buildDetails(context, book);
        },
      ),
    );
  }

  Widget _buildDetails(BuildContext context, Book book) {
    final theme = Theme.of(context);
    final progress = book.totalPages > 0
        ? (book.currentPage / book.totalPages).clamp(0.0, 1.0)
        : 0.0;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.formWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact =
                            constraints.maxWidth < AppSpacing.compactBreakpoint;
                        final cover = BookCover(
                          book,
                          width: AppSpacing.detailCoverWidth,
                          height: AppSpacing.detailCoverHeight,
                        );
                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(child: cover),
                              const SizedBox(height: AppSpacing.lg),
                              _BookHeading(book, centered: true),
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            cover,
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(child: _BookHeading(book)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      AppStrings.readingProgress,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: AppSpacing.progressHeight,
                      borderRadius: BorderRadius.circular(AppSpacing.sm),
                      semanticsLabel: AppStrings.readingProgress,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      AppStrings.pagesProgress(
                        book.currentPage,
                        book.totalPages,
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        FilledButton.icon(
                          onPressed: _deleting
                              ? null
                              : () => context.goNamed(
                                  AppRoutes.bookEdit,
                                  pathParameters: {'id': book.id},
                                ),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text(AppStrings.editBook),
                        ),
                        OutlinedButton.icon(
                          onPressed: _deleting ? null : () => _delete(book),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                          ),
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: Text(
                            _deleting
                                ? AppStrings.deletingBook
                                : AppStrings.deleteBook,
                          ),
                        ),
                      ],
                    ),
                    if (_deleteError != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _deleteError!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.bookInformation,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _InformationRow(
                      label: AppStrings.author,
                      value: book.author,
                    ),
                    _InformationRow(
                      label: AppStrings.genre,
                      value: book.genre.isEmpty
                          ? AppStrings.noGenre
                          : book.genre,
                    ),
                    _InformationRow(
                      label: AppStrings.pages,
                      value: book.totalPages.toString(),
                    ),
                    _InformationRow(
                      label: AppStrings.status,
                      value: BookLabels.status(book.status),
                    ),
                    if (book.createdAt != null)
                      _InformationRow(
                        label: AppStrings.addedOn,
                        value: Formatters.date(book.createdAt!),
                      ),
                    if (book.updatedAt != null)
                      _InformationRow(
                        label: AppStrings.lastUpdated,
                        value: Formatters.date(book.updatedAt!),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(AppStrings.notes, style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      book.notes.isEmpty ? AppStrings.noNotes : book.notes,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: book.notes.isEmpty
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookHeading extends StatelessWidget {
  const _BookHeading(this.book, {this.centered = false});

  final Book book;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textAlign = centered ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        StatusBadge(book.status),
        const SizedBox(height: AppSpacing.md),
        Text(
          book.title,
          textAlign: textAlign,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          book.author,
          textAlign: textAlign,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppStrings.pagesTotal(book.totalPages),
          textAlign: textAlign,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _InformationRow extends StatelessWidget {
  const _InformationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
