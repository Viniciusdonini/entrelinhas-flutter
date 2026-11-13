import 'dart:convert';

import 'package:entrelinhas/core/constants/service_messages.dart';
import 'package:entrelinhas/core/network/api_client.dart';
import 'package:entrelinhas/core/network/api_exception.dart';
import 'package:entrelinhas/repositories/api_auth_repository.dart';
import 'package:entrelinhas/repositories/api_book_repository.dart';
import 'package:entrelinhas/services/auth_service.dart';
import 'package:entrelinhas/services/service_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'repository converts JSON and sends bearer without client timestamps',
    () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        baseUri: Uri.parse('http://localhost:8000/api'),
        client: MockClient((request) async {
          requests.add(request);
          if (request.method == 'DELETE') return http.Response('', 204);
          if (request.method == 'GET' && request.url.path == '/api/books') {
            return _json({
              'data': [_bookJson()],
            });
          }
          return _json({
            'data': _bookJson(),
          }, request.method == 'POST' ? 201 : 200);
        }),
      )..setToken('token-only-for-test');
      addTearDown(client.close);
      final repository = ApiBookRepository(client);
      final books = await repository.listBooks();
      expect(books.single.id, '42');
      expect(books.single.createdAt, DateTime.utc(2026, 11, 13));
      final book = await repository.getBook('42');
      expect(book!.author, 'Autora');
      expect(await repository.createBook(book), '42');
      await repository.updateBook(book.copyWith(coverUrl: ''));
      await repository.deleteBook('42');
      expect(requests.map((r) => r.method), [
        'GET',
        'GET',
        'POST',
        'PUT',
        'DELETE',
      ]);
      for (final request in requests) {
        expect(request.headers['Authorization'], 'Bearer token-only-for-test');
        expect(request.headers['Accept'], 'application/json');
        expect(request.url.path, startsWith('/api/books'));
      }
      final created = jsonDecode(requests[2].body) as Map;
      expect(created.containsKey('id'), isFalse);
      expect(created.containsKey('createdAt'), isFalse);
      expect(created.containsKey('updatedAt'), isFalse);
      expect((jsonDecode(requests[3].body) as Map)['coverUrl'], '');
    },
  );

  test(
    'missing book returns null while malformed successful data fails safely',
    () async {
      var missing = true;
      final client = ApiClient(
        baseUri: Uri.parse('https://example.test/api/'),
        client: MockClient(
          (_) async => missing
              ? _json({'message': 'Not found'}, 404)
              : _json({
                  'data': {'id': 1},
                }),
        ),
      );
      addTearDown(client.close);
      final repository = ApiBookRepository(client);
      expect(await repository.getBook('99'), isNull);
      missing = false;
      await expectLater(
        repository.getBook('1'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            ServiceMessages.invalidBookData,
          ),
        ),
      );
    },
  );

  test(
    'auth maps user, retains token in memory, and revokes it on logout',
    () async {
      final requests = <http.Request>[];
      final client = ApiClient(
        baseUri: Uri.parse('https://example.test/api/'),
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/logout')) {
            return http.Response('', 204);
          }
          return _json({
            'data': {
              'user': {
                'id': 7,
                'name': 'Leitora',
                'email': 'leitora@example.test',
              },
              'token': 'ephemeral-test-token',
            },
          });
        }),
      );
      final auth = AuthService(
        repository: ApiAuthRepository(client),
        client: client,
      );
      addTearDown(auth.dispose);
      var changes = 0;
      auth.addListener(() => changes++);
      await auth.login(
        email: ' leitora@example.test ',
        password: 'not-a-real-password',
      );
      expect(auth.user!.id, '7');
      expect(auth.isAuthenticated, isTrue);
      expect(requests.first.headers.containsKey('Authorization'), isFalse);
      expect(
        (jsonDecode(requests.first.body) as Map)['email'],
        'leitora@example.test',
      );
      await auth.logout();
      expect(
        requests.last.headers['Authorization'],
        'Bearer ephemeral-test-token',
      );
      expect(auth.isAuthenticated, isFalse);
      expect(changes, 2);
    },
  );

  test('401 on authenticated request clears session; failed login stays unauthenticated', () async {
    var authenticated = false;
    final client = ApiClient(
      baseUri: Uri.parse('https://example.test/api/'),
      client: MockClient((request) async {
        if (request.url.path.endsWith('/login') && !authenticated) {
          authenticated = true;
          return _json({
            'data': {
              'user': {
                'id': 1,
                'name': 'Pessoa',
                'email': 'pessoa@example.test',
              },
              'token': 'ephemeral',
            },
          });
        }
        return _json({'message': 'Unauthenticated'}, 401);
      }),
    );
    final auth = AuthService(
      repository: ApiAuthRepository(client),
      client: client,
    );
    addTearDown(auth.dispose);
    await auth.login(
      email: 'pessoa@example.test',
      password: 'not-a-real-password',
    );
    await expectLater(
      ApiBookRepository(client).listBooks(),
      throwsA(isA<ApiException>()),
    );
    expect(auth.isAuthenticated, isFalse);
    await expectLater(
      auth.login(email: 'pessoa@example.test', password: 'wrong-password'),
      throwsA(
        isA<ServiceException>().having(
          (e) => e.message,
          'message',
          ServiceMessages.invalidCredentials,
        ),
      ),
    );
    expect(auth.isAuthenticated, isFalse);
  });

  test(
    'validation errors are readable and server traces never reach UI',
    () async {
      var status = 422;
      final client = ApiClient(
        baseUri: Uri.parse('https://example.test/api/'),
        client: MockClient(
          (_) async => _json({
            'message': 'sensitive internal trace',
            'errors': {
              'title': ['Informe o título.'],
            },
            'trace': ['internal stack'],
          }, status),
        ),
      );
      addTearDown(client.close);
      await expectLater(
        client.request('POST', 'books'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Informe o título.',
          ),
        ),
      );
      status = 500;
      await expectLater(
        client.request('GET', 'books'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            ServiceMessages.serverUnavailable,
          ),
        ),
      );
    },
  );

  test('transport failure is controlled', () async {
    final client = ApiClient(
      baseUri: Uri.parse('https://example.test/api/'),
      client: MockClient(
        (_) async => throw http.ClientException('internal network detail'),
      ),
    );
    addTearDown(client.close);
    await expectLater(
      client.request('GET', 'books'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          ServiceMessages.serverUnavailable,
        ),
      ),
    );
  });
}

http.Response _json(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _bookJson() => {
  'id': 42,
  'title': 'Livro de teste',
  'author': 'Autora',
  'genre': 'Romance',
  'totalPages': 120,
  'currentPage': 0,
  'status': 'wantToRead',
  'notes': '',
  'coverUrl': '',
  'createdAt': '2026-11-13T00:00:00Z',
  'updatedAt': '2026-11-13T00:00:00Z',
};
