import 'dart:convert';

import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:test/test.dart';

void main() {
  test('.toString() returns a string representation of the record', () {
    var userAttribute = CognitoUserAttribute(name: 'name', value: 'Jon');
    expect(userAttribute.toString(), equals('{"Name":"name","Value":"Jon"}'));
  });

  test('.toJson() returns flat Map representing the record', () {
    var userAttribute = CognitoUserAttribute(name: 'name', value: 'Jason');
    final attributeResult = {
      'Name': 'name',
      'Value': 'Jason',
    };
    expect(userAttribute.toJson(), equals(attributeResult));
  });
  test('json.encode(userAttribute) returns valid JSON string', () {
    var userAttribute = CognitoUserAttribute(name: 'name', value: 'Jeremy');
    expect(
        json.encode(userAttribute), equals('{"Name":"name","Value":"Jeremy"}'));
  });
  test('json.encode(List<CognitoUserAttribute>) returns valid JSON string', () {
    final attributes = [
      CognitoUserAttribute(name: 'first_name', value: 'Josh'),
      CognitoUserAttribute(name: 'last_name', value: 'Ong'),
    ];
    expect(
      json.encode(attributes),
      equals(
          '[{"Name":"first_name","Value":"Josh"},{"Name":"last_name","Value":"Ong"}]'),
    );
  });
}
