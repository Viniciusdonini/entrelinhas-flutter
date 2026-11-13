import '../models/app_user.dart';
import '../models/auth_session.dart';

abstract interface class AuthRepository {
  Future<AuthSession> login({required String email, required String password});
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String confirmation,
  });
  Future<AppUser> me();
  Future<void> logout();
}
