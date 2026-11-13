import 'package:flutter/foundation.dart';

import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/app_user.dart';
import '../repositories/auth_repository.dart';
import 'service_exception.dart';

/// The access token lives in memory and is never printed or persisted in code.
class AuthService extends ChangeNotifier {
  AuthService({required this._repository, required this._client}) {
    _client.onUnauthorized = _clearSession;
  }

  final AuthRepository _repository;
  final ApiClient _client;
  AppUser? _user;

  AppUser? get user => _user;
  bool get isAuthenticated => _user != null;

  Future<void> login({required String email, required String password}) async {
    try {
      final session = await _repository.login(
        email: email.trim(),
        password: password,
      );
      _client.setToken(session.token);
      _user = session.user;
      notifyListeners();
    } on ApiException catch (error) {
      throw ServiceException(error.message);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String confirmation,
  }) async {
    try {
      final session = await _repository.register(
        name: name.trim(),
        email: email.trim(),
        password: password,
        confirmation: confirmation,
      );
      _client.setToken(session.token);
      _user = session.user;
      notifyListeners();
    } on ApiException catch (error) {
      throw ServiceException(error.message);
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
      _clearSession();
    } on ApiException catch (error) {
      throw ServiceException(error.message);
    }
  }

  void _clearSession() {
    _client.setToken(null);
    if (_user == null) return;
    _user = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _client.onUnauthorized = null;
    _client.close();
    super.dispose();
  }
}
