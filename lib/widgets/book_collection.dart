import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../models/book.dart';
import 'book_card.dart';

class BookCollection extends StatelessWidget {
  const BookCollection({super.key, required this.books});
  final List<Book> books;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= AppSpacing.desktopBreakpoint
          ? 2
          : 1;
      final width =
          (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
      return Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.md,
        children: [
          for (final book in books)
            SizedBox(
              width: width,
              child: BookCard(book: book),
            ),
        ],
      );
    },
  );
}
