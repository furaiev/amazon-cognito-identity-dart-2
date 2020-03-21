import 'dart:async';

import 'package:amazon_cognito_identity_dart_2/src/client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('initiating Client should set default endpoint based on region', () {
    final client = Client(
      region: 'ap-southeast-1',
    );
    expect(client.endpoint,
        equals('https://cognito-idp.ap-southeast-1.amazonaws.com/'));
  });

  test('initiating Client with endpoint should use endpoint', () {
    final client = Client(
      endpoint: 'https://cognito-idp.custom-region.aws.com',
      region: 'ap-southeaset-10',
    );
    expect(
        client.endpoint, equals('https://cognito-idp.custom-region.aws.com'));
  });

  group('requests', () {
    final testClient = MockClient((request) {
      switch (request.url.path) {
        case '/200':
          return Future<http.Response>.value(http.Response(
            '{"it":"works"}',
            200,
            headers: Map<String, String>.from({
              'Content-Type': 'application/json',
            }),
          ));
          break;
        case '/400_unknown_error':
          return Future.value(http.Response('', 400));
          break;
        case '/400___type':
          return Future.value(http.Response(
              '{"__type": "NotAuthorizedException", '
              '"message": "Logins don\'t match. Please include at least '
              'one valid login for this identity or identity pool."}',
              400));
          break;
        case '/400_x-amzn-ErrorType':
          return Future<http.Response>.value(http.Response(
              '{"message":"1 validation error detected: Value null at '
              '\'InstallS3Bucket\' failed to satisfy constraint: Member'
              ' must not be null"}',
              400,
              headers: Map<String, String>.from({
                'x-amzn-RequestId': 'b0e91dc8-3807-11e2-83c6-5912bf8ad066',
                'x-amzn-ErrorType': 'ValidationException',
                'Content-Type': 'application/json',
                'Content-Length': '124',
                'Date': 'Mon, 26 Nov 2012 20:27:25 GMT'
              })));
        default:
          return Future<http.Response>.value(http.Response('', 404));
      }
    });
    test('200 OK should return data', () async {
      final client = Client(
        region: 'ap-southeast-1',
        client: testClient,
      );
      final paramsReq = {
        'color': 'Blue',
      };
      final data =
          await client.request('TestOperation', paramsReq, endpoint: '/200');
      expect(data['it'], equals('works'));
    });
    test('400 unknown error throws default exception', () async {
      final client = Client(
        region: 'ap-southeast-1',
        client: testClient,
      );
      final paramsReq = {
        'color': 'Green',
      };
      var data;
      try {
        data = await client.request('TestOperation', paramsReq,
            endpoint: '/400_unknown_error');
      } catch (e) {
        expect(e.code, equals('UnknownError'));
        expect(e.name, equals('UnknownError'));
        expect(e.statusCode, equals(400));
        expect(e.message,
            equals('Cognito client request error with unknown message'));
      }
      expect(data, isNull);
    });
    test('400 error __type throws exception with correct code', () async {
      final client = Client(
        region: 'ap-southeast-1',
        client: testClient,
      );
      final paramsReq = {
        'color': 'Green',
      };
      var data;
      try {
        data = await client.request('TestOperation', paramsReq,
            endpoint: '/400___type');
      } catch (e) {
        expect(e.code, equals('NotAuthorizedException'));
        expect(e.name, equals('NotAuthorizedException'));
        expect(e.statusCode, equals(400));
        expect(
            e.message,
            equals('Logins don\'t match. Please include at least '
                'one valid login for this identity or identity pool.'));
      }
      expect(data, isNull);
    });
    test('400 x-amzn-ErrorType throws exception with correct code', () async {
      final client = Client(
        region: 'ap-southeast-1',
        client: testClient,
      );
      final paramsReq = {
        'color': 'Green',
      };
      var data;
      try {
        data = await client.request('TestOperation', paramsReq,
            endpoint: '/400_x-amzn-ErrorType');
      } catch (e) {
        expect(e.code, equals('ValidationException'));
        expect(e.name, equals('ValidationException'));
        expect(e.statusCode, equals(400));
        expect(
            e.message,
            equals('1 validation error detected: Value null at '
                '\'InstallS3Bucket\' failed to satisfy constraint: Member'
                ' must not be null'));
        expect(e.statusCode, 400);
      }
      expect(data, isNull);
    });
  });
}
