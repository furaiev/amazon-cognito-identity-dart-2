abstract class ParamsDecorator {
  Future<Map<String, Object?>> call(Map<String, Object?> params);
}

class NoOpsParamsDecorator extends ParamsDecorator {
  @override
  Future<Map<String, Object?>> call(Map<String, Object?> params) async {
    return params;
  }
}
