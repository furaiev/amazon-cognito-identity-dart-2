import 'package:amazon_cognito_identity_dart_2/src/random_string_helper.dart';
import 'package:test/test.dart';

void main() {
  test('.generates() generates correct length', () {
    expect(RandomString().generate(length: 16).length, equals(16));
  });
  test('.generates() generates with default hex chars', () {
    expect(RandomString().generate(), contains(RegExp(r'[0-9a-f]*')));
  });
}
