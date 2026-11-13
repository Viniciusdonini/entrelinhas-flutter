import 'dart:convert';

import 'package:entrelinhas/app.dart';
import 'package:entrelinhas/core/constants/app_strings.dart';
import 'package:entrelinhas/core/network/api_client.dart';
import 'package:entrelinhas/repositories/api_auth_repository.dart';
import 'package:entrelinhas/repositories/api_book_repository.dart';
import 'package:entrelinhas/services/auth_service.dart';
import 'package:entrelinhas/services/library_book_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets(
    'login validates, displays failure, enters library and logs out',
    (tester) async {
      var rejectLogin = true;
      final requests = <http.Request>[];
      final client = ApiClient(
        baseUri: Uri.parse('https://example.test/api/'),
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/login')) {
            return rejectLogin
                ? _json({'message': 'Invalid credentials'}, 401)
                : _session();
          }
          if (request.url.path.endsWith('/logout')) {
            return http.Response('', 204);
          }
          return _json({'data': []});
        }),
      );
      final auth = AuthService(
        repository: ApiAuthRepository(client),
        client: client,
      );
      final books = LibraryBookService(ApiBookRepository(client));
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        auth.dispose();
        await books.dispose();
      });
      await tester.pumpWidget(App.api(authService: auth, bookService: books));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.loginTitle), findsOneWidget);
      await _tap(tester, find.byKey(const ValueKey('auth-submit')));
      expect(find.text(AppStrings.emailInvalid), findsOneWidget);
      expect(requests, isEmpty);
      await _field(tester, 'auth-email', 'leitora@example.test');
      await _field(tester, 'auth-password', 'not-a-real-password');
      await _tap(tester, find.byKey(const ValueKey('auth-submit')));
      expect(auth.isAuthenticated, isFalse);
      expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
      rejectLogin = false;
      await _tap(tester, find.byKey(const ValueKey('auth-submit')));
      expect(auth.isAuthenticated, isTrue);
      expect(find.text(AppStrings.homePageTitle), findsOneWidget);
      await _tap(tester, find.text(AppStrings.about));
      expect(find.text('leitora@example.test'), findsOneWidget);
      await _tap(tester, find.text(AppStrings.logout));
      expect(auth.isAuthenticated, isFalse);
      expect(find.text(AppStrings.loginTitle), findsOneWidget);
      expect(
        requests.last.headers['Authorization'],
        'Bearer widget-test-token',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'registration requires matching passwords and sends confirmation',
    (tester) async {
      final requests = <http.Request>[];
      final client = ApiClient(
        baseUri: Uri.parse('https://example.test/api/'),
        client: MockClient((request) async {
          requests.add(request);
          return request.url.path.endsWith('/register')
              ? _session()
              : _json({'data': []});
        }),
      );
      final auth = AuthService(
        repository: ApiAuthRepository(client),
        client: client,
      );
      final books = LibraryBookService(ApiBookRepository(client));
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        auth.dispose();
        await books.dispose();
      });
      await tester.pumpWidget(App.api(authService: auth, bookService: books));
      await tester.pumpAndSettle();
      await _tap(tester, find.text(AppStrings.needAccount));
      expect(find.text(AppStrings.registerTitle), findsOneWidget);
      await _field(tester, 'auth-name', 'Leitora');
      await _field(tester, 'auth-email', 'leitora@example.test');
      await _field(tester, 'auth-password', 'not-a-real-password');
      await _field(tester, 'auth-confirm-password', 'different-password');
      await _tap(tester, find.byKey(const ValueKey('auth-submit')));
      expect(find.text(AppStrings.passwordsDifferent), findsOneWidget);
      expect(requests, isEmpty);
      await _field(tester, 'auth-confirm-password', 'not-a-real-password');
      await _tap(tester, find.byKey(const ValueKey('auth-submit')));
      expect(auth.isAuthenticated, isTrue);
      final body = jsonDecode(requests.first.body) as Map;
      expect(body['name'], 'Leitora');
      expect(body['password_confirmation'], body['password']);
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _field(WidgetTester tester, String key, String text) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
http.Response _session() => _json({
  'data': {
    'user': {'id': 1, 'name': 'Leitora', 'email': 'leitora@example.test'},
    'token': 'widget-test-token',
  },
});
