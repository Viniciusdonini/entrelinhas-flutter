import 'dart:convert';

import 'package:entrelinhas/models/book.dart';
import 'package:entrelinhas/models/book_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Book serialization', () {
    test('round-trips all fields through JSON without Firebase types', () {
      final original = Book(
        id: 'book-1',
        title: 'Uma biblioteca própria',
        author: 'Autora de exemplo',
        totalPages: 320,
        genre: 'Romance',
        currentPage: 80,
        status: BookStatus.reading,
        notes: 'Retomar no capítulo cinco.',
        coverUrl: 'https://example.com/capas/biblioteca.jpg',
        createdAt: DateTime.utc(2026, 11, 1),
        updatedAt: DateTime.utc(2026, 11, 9, 12),
      );

      final jsonData = jsonDecode(jsonEncode(original.toMap()));
      final restored = Book.fromMap(
        id: original.id,
        data: jsonData as Map<String, dynamic>,
      );

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.author, original.author);
      expect(restored.totalPages, original.totalPages);
      expect(restored.genre, original.genre);
      expect(restored.currentPage, original.currentPage);
      expect(restored.status, original.status);
      expect(restored.notes, original.notes);
      expect(restored.coverUrl, original.coverUrl);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
      expect(original.toMap().containsKey('id'), isFalse);
    });

    test('accepts a new book without server-generated timestamps', () {
      final book = Book.fromMap(
        id: 'new-book',
        data: {'title': 'Novo livro', 'author': 'Autor', 'totalPages': 100},
      );

      expect(book.status, BookStatus.wantToRead);
      expect(book.currentPage, 0);
      expect(book.genre, isEmpty);
      expect(book.notes, isEmpty);
      expect(book.coverUrl, isEmpty);
      expect(book.createdAt, isNull);
      expect(book.updatedAt, isNull);
    });

    test('accepts legacy records with a null cover URL', () {
      final book = Book.fromMap(
        id: 'legacy-book',
        data: {
          'title': 'Livro anterior às capas',
          'author': 'Autora',
          'totalPages': 100,
          'coverUrl': null,
        },
      );

      expect(book.coverUrl, isEmpty);
      expect(book.toMap()['coverUrl'], isEmpty);
    });

    test('copyWith preserves, replaces and explicitly removes a cover URL', () {
      const original = Book(
        id: 'book-with-cover',
        title: 'Livro com capa',
        author: 'Autora',
        totalPages: 100,
        coverUrl: 'https://example.com/original.jpg',
      );

      expect(
        original.copyWith(title: 'Outro título').coverUrl,
        original.coverUrl,
      );
      expect(
        original.copyWith(coverUrl: 'https://example.com/nova.jpg').coverUrl,
        'https://example.com/nova.jpg',
      );
      final withoutCover = original.copyWith(coverUrl: '');
      expect(withoutCover.coverUrl, isEmpty);
      expect(withoutCover.toMap()['coverUrl'], isEmpty);
      expect(original.coverUrl, 'https://example.com/original.jpg');
      expect(withoutCover.id, original.id);
    });

    test('rejects unknown statuses rather than silently changing data', () {
      expect(
        () => Book.fromMap(
          id: 'invalid-book',
          data: {
            'title': 'Livro',
            'author': 'Autor',
            'totalPages': 100,
            'status': 'unknown',
          },
        ),
        throwsArgumentError,
      );
    });

    test('copyWith keeps identity and creation date while editing', () {
      final original = Book(
        id: 'book-1',
        title: 'Título inicial',
        author: 'Autor',
        totalPages: 100,
        createdAt: DateTime.utc(2026, 11, 1),
      );
      final edited = original.copyWith(
        title: 'Título revisado',
        currentPage: 100,
        status: BookStatus.finished,
      );

      expect(edited.id, original.id);
      expect(edited.createdAt, original.createdAt);
      expect(edited.author, original.author);
      expect(edited.title, 'Título revisado');
      expect(edited.currentPage, 100);
      expect(edited.status, BookStatus.finished);
      expect(original.title, 'Título inicial');
      expect(original.currentPage, 0);
    });
  });
}
