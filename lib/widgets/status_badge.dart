import 'package:flutter/material.dart';

import '../core/constants/book_labels.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/book_status.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final BookStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (status) {
      BookStatus.wantToRead => (
        AppColors.background,
        AppColors.ink,
        Icons.bookmark_border_rounded,
      ),
      BookStatus.reading => (
        AppColors.sage,
        AppColors.primary,
        Icons.auto_stories_outlined,
      ),
      BookStatus.finished => (
        Color.lerp(
          AppColors.surface,
          AppColors.terracotta,
          AppColors.finishedTint,
        )!,
        Color.lerp(AppColors.terracotta, AppColors.ink, AppColors.coverShade)!,
        Icons.check_circle_outline_rounded,
      ),
    };
    final label = BookLabels.status(status);

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.badgeHorizontalPadding,
          vertical: AppSpacing.badgeVerticalPadding,
        ),
        decoration: ShapeDecoration(
          color: background,
          shape: const StadiumBorder(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: foreground, size: AppSpacing.badgeIconSize),
            const SizedBox(width: AppSpacing.xxs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
