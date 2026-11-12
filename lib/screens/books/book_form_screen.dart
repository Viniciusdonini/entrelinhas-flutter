import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/book_labels.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/validators.dart';
import '../../models/book.dart';
import '../../models/book_status.dart';
import '../../services/book_service.dart';
import '../../services/service_exception.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/async_state_view.dart';

class BookFormScreen extends StatefulWidget {
  const BookFormScreen({super.key, required this.service, this.bookId});

  final BookService service;
  final String? bookId;

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _genreController = TextEditingController();
  final _totalPagesController = TextEditingController();
  final _currentPageController = TextEditingController(text: '0');
  final _notesController = TextEditingController();

  BookStatus _status = BookStatus.wantToRead;
  Book? _existingBook;
  bool _loading = false;
  bool _missing = false;
  bool _saving = false;
  int _loadGeneration = 0;
  String? _loadError;
  String? _saveError;

  bool get _isEditing => widget.bookId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadBook();
    }
  }

  @override
  void didUpdateWidget(covariant BookFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bookId != widget.bookId ||
        oldWidget.service != widget.service) {
      if (_isEditing) {
        _loadBook();
      } else {
        _loadGeneration++;
        _loading = false;
        _existingBook = null;
        _missing = false;
        _loadError = null;
        _saveError = null;
        _status = BookStatus.wantToRead;
        for (final controller in [
          _titleController,
          _authorController,
          _genreController,
          _totalPagesController,
          _notesController,
        ]) {
          controller.clear();
        }
        _currentPageController.text = '0';
      }
    }
  }

  Future<void> _loadBook() async {
    final loadGeneration = ++_loadGeneration;
    setState(() {
      _loading = true;
      _missing = false;
      _loadError = null;
    });
    try {
      final book = await widget.service.getBook(widget.bookId!);
      if (!_isCurrentLoad(loadGeneration)) return;
      if (book == null) {
        setState(() => _missing = true);
        return;
      }
      _existingBook = book;
      _titleController.text = book.title;
      _authorController.text = book.author;
      _genreController.text = book.genre;
      _totalPagesController.text = book.totalPages.toString();
      _currentPageController.text = book.currentPage.toString();
      _notesController.text = book.notes;
      _status = book.status;
    } on ServiceException catch (error) {
      if (_isCurrentLoad(loadGeneration)) {
        setState(() => _loadError = error.message);
      }
    } catch (_) {
      if (_isCurrentLoad(loadGeneration)) {
        setState(() => _loadError = AppStrings.loadBookError);
      }
    } finally {
      if (_isCurrentLoad(loadGeneration)) setState(() => _loading = false);
    }
  }

  bool _isCurrentLoad(int generation) =>
      mounted && generation == _loadGeneration;

  void _changeStatus(BookStatus? value) {
    if (value == null) return;
    setState(() {
      _status = value;
      if (value == BookStatus.wantToRead) {
        _currentPageController.text = '0';
      } else if (value == BookStatus.finished) {
        _currentPageController.text = _totalPagesController.text;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final totalPages = int.tryParse(_totalPagesController.text.trim());
    if (_status == BookStatus.finished && totalPages != null) {
      _currentPageController.text = totalPages.toString();
    } else if (_status == BookStatus.wantToRead) {
      _currentPageController.text = '0';
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _saveError = null;
    });

    final currentPage = int.parse(_currentPageController.text.trim());
    final effectiveStatus = currentPage == totalPages
        ? BookStatus.finished
        : _status;
    final book = Book(
      id: _existingBook?.id ?? '',
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      genre: _genreController.text.trim(),
      totalPages: totalPages!,
      currentPage: currentPage,
      status: effectiveStatus,
      notes: _notesController.text.trim(),
      createdAt: _existingBook?.createdAt,
      updatedAt: _existingBook?.updatedAt,
    );

    try {
      final String id;
      if (_isEditing) {
        await widget.service.updateBook(book);
        id = book.id;
      } else {
        id = await widget.service.createBook(book);
      }
      if (!mounted) return;
      context.goNamed(AppRoutes.bookDetails, pathParameters: {'id': id});
    } on ServiceException catch (error) {
      if (mounted) setState(() => _saveError = error.message);
    } catch (_) {
      if (mounted) setState(() => _saveError = AppStrings.saveBookError);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _cancel() {
    if (_isEditing) {
      context.goNamed(
        AppRoutes.bookDetails,
        pathParameters: {'id': widget.bookId!},
      );
    } else {
      context.goNamed(AppRoutes.books);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _genreController.dispose();
    _totalPagesController.dispose();
    _currentPageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget content;
    if (_loading) {
      content = const AsyncStateView.loading();
    } else if (_loadError != null) {
      content = AsyncStateView.error(message: _loadError, onRetry: _loadBook);
    } else if (_missing) {
      content = AsyncStateView.empty(
        title: AppStrings.bookNotFoundTitle,
        message: AppStrings.bookNotFoundMessage,
        action: FilledButton(
          onPressed: () => context.goNamed(AppRoutes.books),
          child: const Text(AppStrings.backToLibrary),
        ),
      );
    } else {
      content = Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSpacing.formWidth),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.bookInformation,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      key: const ValueKey('book-title'),
                      controller: _titleController,
                      enabled: !_saving,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: AppStrings.bookTitleLabel,
                        hintText: AppStrings.bookTitleHint,
                      ),
                      validator: Validators.title,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      key: const ValueKey('book-author'),
                      controller: _authorController,
                      enabled: !_saving,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: AppStrings.authorLabel,
                        hintText: AppStrings.authorHint,
                      ),
                      validator: Validators.author,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      key: const ValueKey('book-genre'),
                      controller: _genreController,
                      enabled: !_saving,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: AppStrings.genreLabel,
                        hintText: AppStrings.genreHint,
                      ),
                      validator: Validators.genre,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      key: const ValueKey('book-total-pages'),
                      controller: _totalPagesController,
                      enabled: !_saving,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: AppStrings.totalPagesLabel,
                        hintText: AppStrings.totalPagesHint,
                      ),
                      validator: Validators.totalPages,
                      onChanged: (value) {
                        if (_status == BookStatus.finished) {
                          _currentPageController.text = value;
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    DropdownButtonFormField<BookStatus>(
                      key: ValueKey(_status),
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: AppStrings.statusLabel,
                      ),
                      items: [
                        for (final status in BookStatus.values)
                          DropdownMenuItem(
                            value: status,
                            child: Text(BookLabels.status(status)),
                          ),
                      ],
                      onChanged: _saving ? null : _changeStatus,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      key: const ValueKey('book-current-page'),
                      controller: _currentPageController,
                      enabled: !_saving && _status == BookStatus.reading,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: AppStrings.currentPageLabel,
                        helperText: AppStrings.readingProgressHint,
                        helperMaxLines: 3,
                      ),
                      validator: (value) => Validators.currentPage(
                        value,
                        totalPages:
                            int.tryParse(_totalPagesController.text.trim()) ??
                            0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      key: const ValueKey('book-notes'),
                      controller: _notesController,
                      enabled: !_saving,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      minLines: 3,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: AppStrings.notesLabel,
                        hintText: AppStrings.notesHint,
                        alignLabelWithHint: true,
                      ),
                      validator: Validators.notes,
                    ),
                    if (_saveError != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(AppSpacing.sm),
                        ),
                        child: Text(
                          _saveError!,
                          style: TextStyle(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: AppSpacing.lg,
                              child: CircularProgressIndicator(),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _saving ? AppStrings.savingBook : AppStrings.saveBook,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: _saving ? null : _cancel,
                      child: const Text(AppStrings.cancel),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AppScaffold(
      title: _isEditing ? AppStrings.editBookTitle : AppStrings.newBookTitle,
      subtitle: AppStrings.formSubtitle,
      child: content,
    );
  }
}
