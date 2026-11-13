import '../core/constants/service_messages.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/app_user.dart';
import '../models/auth_session.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client);

  final ApiClient _client;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async => _decode(
    await _client.request(
      'POST',
      'auth/login',
      authenticated: false,
      body: {'email': email, 'password': password},
    ),
  );

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String confirmation,
  }) async => _decode(
    await _client.request(
      'POST',
      'auth/register',
      authenticated: false,
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': confirmation,
      },
    ),
  );

  @override
  Future<AppUser> me() async {
    try {
      final json = await _client.request('GET', 'auth/me');
      return AppUser.fromJson(json['data'] as Map<String, dynamic>);
    } on ApiException {
      rethrow;
    } on Object {
      throw const ApiException(ServiceMessages.invalidBookData);
    }
  }

  @override
  Future<void> logout() async {
    await _client.request('POST', 'auth/logout');
  }

  AuthSession _decode(Map<String, dynamic> json) {
    try {
      final data = json['data'] as Map<String, dynamic>;
      final token = data['token'] as String;
      if (token.isEmpty) throw const FormatException();
      return AuthSession(
        user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
        token: token,
      );
    } on Object {
      throw const ApiException(ServiceMessages.invalidBookData);
    }
  }
}
