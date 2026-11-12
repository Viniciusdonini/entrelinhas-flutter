import 'package:flutter/material.dart';

import '../core/constants/app_strings.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

class AsyncStateView extends StatelessWidget {
  const AsyncStateView.loading({super.key})
    : _loading = true,
      title = AppStrings.loading,
      message = null,
      action = null,
      onRetry = null;
  const AsyncStateView.error({super.key, this.onRetry, this.message})
    : _loading = false,
      title = AppStrings.errorTitle,
      action = null;
  const AsyncStateView.empty({
    super.key,
    this.title = AppStrings.emptyTitle,
    this.message = AppStrings.emptyMessage,
    this.action,
  }) : _loading = false,
       onRetry = null;
  final bool _loading;
  final String? title;
  final String? message;
  final Widget? action;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxl,
        horizontal: AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_loading)
            const CircularProgressIndicator()
          else
            Icon(
              onRetry == null
                  ? Icons.auto_stories_outlined
                  : Icons.wifi_off_rounded,
              size: AppSpacing.largeIconSize,
              color: AppColors.primary,
            ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title ?? AppStrings.emptyTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (!_loading) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message ?? AppStrings.errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.muted),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    ),
  );
}
