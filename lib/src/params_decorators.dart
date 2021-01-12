abstract class ParamsDecorator {
  Future<void> call(Map<String, Object> params);
}

class NoOpsParamsDecorator extends ParamsDecorator {

  @override
  Future<void> call(Map<String, Object> params) {
    return Future<void>.value();
  }
}
