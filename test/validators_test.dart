import 'package:entrelinhas/core/constants/app_strings.dart';
import 'package:entrelinhas/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Required book information', () {
    test('title and author reject missing and whitespace-only input', () {
      for (final value in <String?>[null, '', '   ', '\t\n']) {
        expect(Validators.title(value), AppStrings.titleRequired);
        expect(Validators.author(value), AppStrings.authorRequired);
      }
    });

    test('title accepts 120 trimmed characters and rejects 121', () {
      expect(Validators.title('  ${_text(120)}\n'), isNull);
      expect(Validators.title(_text(121)), AppStrings.titleLength);
    });

    test('author accepts 100 trimmed characters and rejects 101', () {
      expect(Validators.author('\t${_text(100)}  '), isNull);
      expect(Validators.author(_text(101)), AppStrings.authorLength);
    });
  });

  group('Optional text fields', () {
    test('genre and notes accept missing or blank input', () {
      for (final value in <String?>[null, '', '   ', '\t\n']) {
        expect(Validators.genre(value), isNull);
        expect(Validators.notes(value), isNull);
      }
    });

    test('genre enforces the 60-character limit after trimming', () {
      expect(Validators.genre('  ${_text(60)}  '), isNull);
      expect(Validators.genre(_text(61)), AppStrings.genreLength);
    });

    test('notes enforce the 2000-character limit after trimming', () {
      expect(Validators.notes('\n${_text(2000)}\n'), isNull);
      expect(Validators.notes(_text(2001)), AppStrings.notesLength);
    });
  });

  group('Page counts', () {
    test(
      'total pages accepts both valid boundaries and surrounding spaces',
      () {
        for (final value in ['1', '20000', ' 240\n']) {
          expect(Validators.totalPages(value), isNull, reason: value);
        }
      },
    );

    test('total pages rejects absent, noninteger and out-of-range values', () {
      for (final value in <String?>[
        null,
        '',
        '   ',
        '0',
        '-1',
        '20001',
        '2.5',
        '1e3',
        'duzentas',
      ]) {
        expect(
          Validators.totalPages(value),
          AppStrings.pagesInvalid,
          reason: 'Invalid total pages: $value',
        );
      }
    });

    test('current page accepts zero, the last page and surrounding spaces', () {
      for (final value in ['0', '100', ' 42\n']) {
        expect(
          Validators.currentPage(value, totalPages: 100),
          isNull,
          reason: value,
        );
      }
    });

    test(
      'current page rejects missing, noninteger and out-of-range values',
      () {
        for (final value in <String?>[
          null,
          '',
          '   ',
          '-1',
          '101',
          '1.5',
          '1e1',
          'dez',
        ]) {
          expect(
            Validators.currentPage(value, totalPages: 100),
            AppStrings.currentPageInvalid,
            reason: 'Invalid current page: $value',
          );
        }
      },
    );

    test('current page respects the total of a one-page book', () {
      expect(Validators.currentPage('1', totalPages: 1), isNull);
      expect(
        Validators.currentPage('2', totalPages: 1),
        AppStrings.currentPageInvalid,
      );
    });
  });

  group('Optional cover URL', () {
    test('accepts missing and blank input', () {
      for (final value in <String?>[null, '', '   ', '\t\n']) {
        expect(Validators.coverUrl(value), isNull);
      }
    });

    test('accepts HTTPS, escaped spaces and image endpoints with queries', () {
      for (final value in [
        'https://example.com/capa.jpg',
        'https://images.example.com/minha%20capa.jpg?size=300&name=Capa%20azul',
        'https://images.example.com/cover?id=42',
      ]) {
        expect(Validators.coverUrl(value), isNull, reason: value);
      }
    });

    test('rejects non-HTTPS schemes and missing schemes', () {
      for (final value in [
        'http://example.com/capa.jpg',
        'file:///capa.jpg',
        'data:image/png;base64,aGVsbG8=',
        'javascript:alert(1)',
        'example.com/capa.jpg',
      ]) {
        expect(Validators.coverUrl(value), isNotNull, reason: value);
      }
    });

    test('rejects credentials in the URL', () {
      for (final value in [
        'https://user:password@example.com/capa.jpg',
        'https://user@example.com/capa.jpg',
      ]) {
        expect(Validators.coverUrl(value), isNotNull, reason: value);
      }
    });

    test('rejects malformed hosts and literal whitespace', () {
      for (final value in [
        'https:///capa.jpg',
        'https://example..com/capa.jpg',
        'https://-example.com/capa.jpg',
        'https://example-.com/capa.jpg',
        'https://exa_mple.com/capa.jpg',
        'https://example.com/capa azul.jpg',
        'https://example.com/capa\n.jpg',
        'https://example.com/\tcapa.jpg',
      ]) {
        expect(Validators.coverUrl(value), isNotNull, reason: value);
      }
    });

    test('accepts 2048 characters and rejects 2049', () {
      const prefix = 'https://example.com/';
      expect(
        Validators.coverUrl('$prefix${_text(2048 - prefix.length)}'),
        isNull,
      );
      expect(
        Validators.coverUrl('$prefix${_text(2049 - prefix.length)}'),
        isNotNull,
      );
    });
  });
}

String _text(int length) => List.filled(length, 'a').join();
