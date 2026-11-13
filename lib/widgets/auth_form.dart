import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_strings.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/validators.dart';
import '../services/auth_service.dart';
import '../services/service_exception.dart';

class AuthForm extends StatefulWidget {
  const AuthForm({super.key, required this.service, this.registering = false});

  final AuthService service;
  final bool registering;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.registering) {
        await widget.service.register(
          name: _name.text,
          email: _email.text,
          password: _password.text,
          confirmation: _confirmation.text,
        );
      } else {
        await widget.service.login(
          email: _email.text,
          password: _password.text,
        );
      }
      if (mounted) context.goNamed(AppRoutes.home);
    } on ServiceException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
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
                children: [
                  if (widget.registering) ...[
                    TextFormField(
                      key: const ValueKey('auth-name'),
                      controller: _name,
                      enabled: !_busy,
                      autofillHints: const [AutofillHints.name],
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: AppStrings.nameLabel,
                      ),
                      validator: Validators.name,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  TextFormField(
                    key: const ValueKey('auth-email'),
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: AppStrings.emailLabel,
                    ),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    key: const ValueKey('auth-password'),
                    controller: _password,
                    enabled: !_busy,
                    obscureText: _obscure,
                    autofillHints: [
                      widget.registering
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: widget.registering
                        ? TextInputAction.next
                        : TextInputAction.done,
                    onFieldSubmitted: widget.registering
                        ? null
                        : (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: AppStrings.passwordLabel,
                      suffixIcon: IconButton(
                        tooltip: _obscure
                            ? AppStrings.showPassword
                            : AppStrings.hidePassword,
                        onPressed: _busy
                            ? null
                            : () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: Validators.password,
                  ),
                  if (widget.registering) ...[
                    const SizedBox(height: AppSpacing.lg),
                    TextFormField(
                      key: const ValueKey('auth-confirm-password'),
                      controller: _confirmation,
                      enabled: !_busy,
                      obscureText: _obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: AppStrings.passwordConfirmationLabel,
                      ),
                      validator: (value) => Validators.passwordConfirmation(
                        value,
                        _password.text,
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    key: const ValueKey('auth-submit'),
                    onPressed: _busy ? null : _submit,
                    child: Text(
                      _busy
                          ? (widget.registering
                                ? AppStrings.registering
                                : AppStrings.authenticating)
                          : (widget.registering
                                ? AppStrings.register
                                : AppStrings.login),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => context.goNamed(
                            widget.registering
                                ? AppRoutes.login
                                : AppRoutes.register,
                          ),
                    child: Text(
                      widget.registering
                          ? AppStrings.alreadyHaveAccount
                          : AppStrings.needAccount,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    AppStrings.sessionInfo,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
