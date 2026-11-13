import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/auth_form.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, required this.service});
  final AuthService service;

  @override
  Widget build(BuildContext context) => AppScaffold(
    title: AppStrings.loginTitle,
    subtitle: AppStrings.loginSubtitle,
    showNavigation: false,
    child: AuthForm(service: service),
  );
}
