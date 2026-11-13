import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_strings.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../services/auth_service.dart';
import '../services/service_exception.dart';

class AccountPanel extends StatefulWidget {
  const AccountPanel({super.key, required this.service});
  final AuthService service;

  @override
  State<AccountPanel> createState() => _AccountPanelState();
}

class _AccountPanelState extends State<AccountPanel> {
  bool _busy = false;
  String? _error;

  Future<void> _logout() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.service.logout();
      if (mounted) context.goNamed(AppRoutes.login);
    } on ServiceException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.service.user;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.signedInAs, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            if (user != null) ...[
              Text(user.name, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(user.email, style: theme.textTheme.bodyMedium),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.error,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            OutlinedButton.icon(
              onPressed: _busy ? null : _logout,
              icon: const Icon(Icons.logout),
              label: Text(_busy ? AppStrings.loggingOut : AppStrings.logout),
            ),
          ],
        ),
      ),
    );
  }
}
