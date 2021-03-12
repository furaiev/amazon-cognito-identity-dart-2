import 'dart:convert';

import 'package:http/http.dart' as http;

import 'cognito_client_exceptions.dart';

class Client {
  String _service;
  String _userAgent;
  String _region;
  String endpoint;
  http.Client _client;

  Client({
    String endpoint,
    String region,
    String service = 'AWSCognitoIdentityProviderService',
    http.Client client,
    String userAgent = 'aws-amplify/0.0.x dart',
  }) {
    _region = region;
    _service = service;
    _userAgent = userAgent;
    this.endpoint = endpoint ?? 'https://cognito-idp.$_region.amazonaws.com/';
    _client = client ?? http.Client();
  }

  /// Makes requests on AWS API service provider
  dynamic request(String operation, Map<String, dynamic> params,
      {String endpoint, String service}) async {
    final endpointReq = endpoint ?? this.endpoint;
    final targetService = service ?? _service;
    final body = json.encode(params);

    final headersReq = {
      'Content-Type': 'application/x-amz-json-1.1',
      'X-Amz-Target': '$targetService.$operation',
      'X-Amz-User-Agent': _userAgent,
    };

    http.Response response;
    try {
      response = await _client.post(
        Uri.parse(endpointReq),
        headers: headersReq,
        body: body,
      );
    } catch (e) {
      if (e.toString().startsWith('SocketException:')) {
        throw CognitoClientException(
          e.message,
          code: 'NetworkError',
        );
      }
      throw CognitoClientException('Unknown Error', code: 'Unknown error');
    }

    var data;

    try {
      data = json.decode(utf8.decode(response.bodyBytes));
    } catch (_) {
      // expect json
    }

    if (response.statusCode < 200 || response.statusCode > 299) {
      var errorType = 'UnknownError';
      for (final header in response.headers.keys) {
        if (header.toLowerCase() == 'x-amzn-errortype') {
          errorType = response.headers[header].split(':')[0];
          break;
        }
      }
      if (data == null) {
        throw CognitoClientException(
          'Cognito client request error with unknown message',
          code: errorType,
          name: errorType,
          statusCode: response.statusCode,
        );
      }
      final String dataType = data['__type'];
      final String dataCode = data['code'];
      final code = (dataType ?? dataCode ?? errorType).split('#').removeLast();
      throw CognitoClientException(
        data['message'] ?? 'Cognito client request error with unknown message',
        code: code,
        name: code,
        statusCode: response.statusCode,
      );
    }
    return data;
  }
}
