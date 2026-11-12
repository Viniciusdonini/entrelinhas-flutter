import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_strings.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.actions,
    this.showNavigation = true,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final bool showNavigation;

  int _index(BuildContext context) {
    final name = GoRouterState.of(context).topRoute?.name;
    if (name == AppRoutes.home) return 0;
    if (name == AppRoutes.about) return 2;
    return 1;
  }

  void _navigate(BuildContext context, int index) => context.goNamed(
    [AppRoutes.home, AppRoutes.books, AppRoutes.about][index],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= AppSpacing.desktopBreakpoint;
        final selected = _index(context);
        return Scaffold(
          bottomNavigationBar: showNavigation && !desktop
              ? NavigationBar(
                  selectedIndex: selected,
                  onDestinationSelected: (index) => _navigate(context, index),
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: AppStrings.home,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.auto_stories_outlined),
                      selectedIcon: Icon(Icons.auto_stories),
                      label: AppStrings.library,
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.info_outline),
                      selectedIcon: Icon(Icons.info),
                      label: AppStrings.about,
                    ),
                  ],
                )
              : null,
          body: SafeArea(
            child: Column(
              children: [
                DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSpacing.contentWidth,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            IconButton.filledTonal(
                              onPressed: () => context.goNamed(AppRoutes.home),
                              tooltip: AppStrings.goHome,
                              icon: const Icon(Icons.auto_stories_outlined),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                AppStrings.appName,
                                style: theme.textTheme.headlineMedium,
                              ),
                            ),
                            if (desktop && showNavigation)
                              ...[
                                AppStrings.home,
                                AppStrings.library,
                                AppStrings.about,
                              ].indexed.map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.only(
                                    left: AppSpacing.xs,
                                  ),
                                  child: TextButton(
                                    onPressed: () =>
                                        _navigate(context, entry.$1),
                                    style: TextButton.styleFrom(
                                      backgroundColor: selected == entry.$1
                                          ? AppColors.sage
                                          : null,
                                    ),
                                    child: Text(entry.$2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppSpacing.contentWidth,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                title,
                                style: desktop
                                    ? theme.textTheme.displaySmall
                                    : theme.textTheme.headlineLarge,
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  subtitle!,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                              if (actions != null) ...[
                                const SizedBox(height: AppSpacing.lg),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: actions!,
                                ),
                              ],
                              const SizedBox(height: AppSpacing.xl),
                              child,
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
