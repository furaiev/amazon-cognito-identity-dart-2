import 'dart:async';

abstract class CognitoStorage {
  Future<dynamic> setItem(String key, value);
  Future<dynamic> getItem(String key);
  Future<dynamic> removeItem(String key);
  Future<void> clear();
}

class CognitoMemoryStorage extends CognitoStorage {
  Map<String, dynamic> _dataMemory = {};
  @override
  Future<dynamic> setItem(String key, value) async {
    _dataMemory[key] = value;
    return _dataMemory[key];
  }

  @override
  Future<dynamic> getItem(String key) async {
    return _dataMemory[key];
  }

  @override
  Future<dynamic> removeItem(String key) async {
    return _dataMemory.remove(key);
  }

  @override
  Future<void> clear() async {
    _dataMemory = {};
  }
}

class CognitoStorageHelper<S extends CognitoStorage> {
  S storage;
  CognitoStorageHelper(this.storage);

  S getStorage() {
    return storage;
  }
}
