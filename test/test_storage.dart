import 'dart:convert';

import 'package:amazon_cognito_identity_dart_2/cognito.dart';

Map<String, String> testStorage = {};

class TestCustomStorage extends CognitoStorage {
  String prefix;
  TestCustomStorage(this.prefix);
  @override
  Future<String> setItem(String key, value) async {
    testStorage[prefix + key] = json.encode(value);
    return testStorage[prefix + key];
  }

  @override
  Future<dynamic> getItem(String key) async {
    if (testStorage[prefix + key] != null) {
      return json.decode(testStorage[prefix + key]);
    }
    return null;
  }

  @override
  Future<String> removeItem(String key) async {
    return testStorage.remove(prefix + key);
  }

  @override
  Future<void> clear() async {
    testStorage = {};
  }
}
