import 'dart:async';

abstract class CognitoStorage {
  Future<dynamic> setItem(String key, value);
  Future<dynamic> getItem(String key);
  Future<dynamic> removeItem(String key);
  Future<void> clear();
}

/// In-memory [CognitoStorage]. Each instance has its own map; instances do not share data.
class CognitoMemoryStorage extends CognitoStorage {
  final Map<String, dynamic> _data = {};

  @override
  Future<dynamic> setItem(String key, value) async {
    _data[key] = value;
    return _data[key];
  }

  @override
  Future<dynamic> getItem(String key) async {
    return _data[key];
  }

  @override
  Future<dynamic> removeItem(String key) async {
    return _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }
}

class CognitoStorageHelper<S extends CognitoStorage> {
  S storage;
  CognitoStorageHelper(this.storage);

  S getStorage() {
    return storage;
  }
}
