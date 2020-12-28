abstract class ParamsDecorator {
  void call(Map<String, Object> params);
}

class AnalyticsMetadataParamsDecorator extends ParamsDecorator {
  final String _analyticsEndpointId;

  AnalyticsMetadataParamsDecorator(this._analyticsEndpointId);

  @override
  void call(Map<String, Object> params) {
    if (_analyticsEndpointId != null) {
      params['AnalyticsMetadata'] = {
        'AnalyticsEndpointId': _analyticsEndpointId
      };
    }
  }
}
