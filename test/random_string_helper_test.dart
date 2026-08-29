import 'package:amazon_cognito_identity_dart_2/src/random_string_helper.dart';
import 'package:test/test.dart';

void main() {
  test('.generates() generates correct length', () {
    expect(RandomString().generate(length: 16).length, equals(16));
  });

  test('.generates() generates with default hex chars', () {
    expect(RandomString().generate(), contains(RegExp(r'[0-9a-f]*')));
  });

  test('.generate() uses all characters in custom charList', () {
    final rs = RandomString(secure: false, seed: 42);
    final result = rs.generate(length: 1000, charList: ['x', 'y', 'z']);

    expect(result.contains('x'), isTrue);
    expect(result.contains('y'), isTrue);
    expect(result.contains('z'), isTrue);
  });

  test('.generate() can generate the last hex character', () {
    final rs = RandomString(secure: false, seed: 123);
    final result = rs.generate(length: 10000);

    expect(result.contains('f'), isTrue);
  });
}
