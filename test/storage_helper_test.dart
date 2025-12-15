import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:test/test.dart';

import 'test_storage.dart';

void main() {
  group('CognitoMemoryStorage', () {
    test('new CognitoStorageHelper() sets up default CognitoMemoryStorage', () {
      final s = CognitoStorageHelper(CognitoMemoryStorage());
      expect(s.getStorage(), const TypeMatcher<CognitoMemoryStorage>());
    });
    test('.getItem() returns default null', () async {
      final s = CognitoStorageHelper(CognitoMemoryStorage()).getStorage();
      expect(await s.getItem('some'), equals(null));
    });
    test('.setItem() sets up item in memory & .getItem() retrieves item',
        () async {
      final s = CognitoStorageHelper(CognitoMemoryStorage()).getStorage();
      await s.setItem('some', 'value');
      expect(await s.getItem('some'), equals('value'));
    });
    test('new instance does not share data with previous instance', () async {
      final s = CognitoStorageHelper(CognitoMemoryStorage()).getStorage();
      expect(await s.getItem('some'), equals(null));
    });
    test('.removeItem() returns item and removes from storage', () async {
      final s = CognitoStorageHelper(CognitoMemoryStorage()).getStorage();
      await s.setItem('another', 'awesome value');
      final removedItem = await s.removeItem('another');
      expect(removedItem, equals('awesome value'));
      expect(await s.getItem('another'), equals(null));
    });
    test('.clear() clears storage', () async {
      final s = CognitoStorageHelper(CognitoMemoryStorage()).getStorage();
      await s.clear();
      expect(await s.getItem('some'), equals(null));
    });
    test('multiple instances are isolated from each other', () async {
      final storage1 = CognitoMemoryStorage();
      final storage2 = CognitoMemoryStorage();
      
      await storage1.setItem('key1', 'value1');
      await storage2.setItem('key2', 'value2');
      
      expect(await storage1.getItem('key1'), equals('value1'));
      expect(await storage1.getItem('key2'), equals(null));
      expect(await storage2.getItem('key1'), equals(null));
      expect(await storage2.getItem('key2'), equals('value2'));
    });
  });
  group('custom storage', () {
    test('new CognitoStorageHelper() sets up default TestCustomStorage', () {
      final s = CognitoStorageHelper(TestCustomStorage('test:'));
      expect(s.getStorage(), const TypeMatcher<TestCustomStorage>());
    });
    test('.setItem() sets up json value with custom prefixed key', () async {
      final s = CognitoStorageHelper(TestCustomStorage('test:')).getStorage();
      final params = {
        'username': 'x123',
        'name': 'Michael',
      };
      await s.setItem('user', params);
      expect(testStorage['test:user'],
          equals('{"username":"x123","name":"Michael"}'));
    });
    test('.getItem() gets item with decoded values', () async {
      final s = CognitoStorageHelper(TestCustomStorage('test:')).getStorage();
      final user = await s.getItem('user');
      expect(user['username'], equals('x123'));
      expect(user['name'], equals('Michael'));
    });
  });
}
