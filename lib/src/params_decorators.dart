abstract class ParamsDecorator {
  void call(Map<String, Object> params);
}

class NoOpsParamsDecorator extends ParamsDecorator {

  @override
  void call(Map<String, Object> params) {}
}
