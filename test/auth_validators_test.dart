import 'package:entrelinhas/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('profile names reject blanks and enforce the documented size', () {
    expect(Validators.name(null), isNotNull);
    expect(Validators.name('  '), isNotNull);
    expect(Validators.name('A'), isNotNull);
    expect(Validators.name(' Vinicius Donini '), isNull);
    expect(Validators.name(List.filled(101, 'a').join()), isNotNull);
  });

  test('email validation rejects missing domain and embedded whitespace', () {
    for (final value in [
      null,
      '',
      'user',
      'user@',
      'user@example',
      'user name@example.test',
    ]) {
      expect(Validators.email(value), isNotNull, reason: '$value');
    }
    expect(Validators.email(' leitora@example.test '), isNull);
  });

  test('password and confirmation must meet size and match exactly', () {
    expect(Validators.password(null), isNotNull);
    expect(Validators.password('1234567'), isNotNull);
    expect(Validators.password('12345678'), isNull);
    expect(Validators.password(List.filled(129, 'a').join()), isNotNull);
    expect(
      Validators.passwordConfirmation('a-different-value', '12345678'),
      isNotNull,
    );
    expect(Validators.passwordConfirmation('12345678', '12345678'), isNull);
  });
}
