import 'dart:convert';

import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'test_storage.dart';

void main() {
  const userPoolId = 'ap-southeast-1_nnnnnnnnn';
  const clientId = 'nnnnnnnnnnnnnnnnnnnnnnnnnn';
  const username = 'testuser';

  /// Minimal valid JWT body used only for session construction in tests.
  const sampleJwt =
      'eyJraWQiOiJ3dzdRQWdvcmhGaXVqK09qcUdtXC9taWhITkFhMHRyRThcL1wvSnNtWU94VG1ZPSIsImFsZyI6IlJTMjU2In0'
      '.eyJzdWIiOiIxYzQyMWYwYy03ZmNlLTQ0MDEtOTVlYy1lYzA1YTBjNzc0NDkiLCJ0b2tlbl91c2UiOiJhY2Nlc3MiLCJleHAiOjk5OTk5OTk5OTl9'
      '.sig';

  setUp(() {
    testStorage = {};
  });

  group('getTokensFromRefreshToken', () {
    test('sends GetTokensFromRefreshToken with ClientId and RefreshToken',
        () async {
      http.Request? captured;
      final mockClient = MockClient((request) async {
        captured = request;
        return http.Response(
          json.encode({
            'AuthenticationResult': {
              'AccessToken': sampleJwt,
              'ExpiresIn': 3600,
              'IdToken': sampleJwt,
              'RefreshToken': 'new-refresh',
              'TokenType': 'Bearer',
            },
          }),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final storage = TestCustomStorage('');
      final pool = CognitoUserPool(
        userPoolId,
        clientId,
        customClient: Client(region: 'ap-southeast-1', client: mockClient),
        storage: storage,
      );
      final user = CognitoUser(username, pool, storage: storage);

      final session = await user.getTokensFromRefreshToken(
        CognitoRefreshToken('old-refresh'),
      );

      expect(
        captured!.headers['X-Amz-Target'],
        'AWSCognitoIdentityProviderService.GetTokensFromRefreshToken',
      );
      final body = json.decode(captured!.body) as Map<String, dynamic>;
      expect(body['ClientId'], clientId);
      expect(body['RefreshToken'], 'old-refresh');
      expect(body.containsKey('ClientSecret'), isFalse);
      expect(body.containsKey('DeviceKey'), isFalse);
      expect(body.containsKey('ClientMetadata'), isFalse);

      expect(session, isNotNull);
      expect(session!.getRefreshToken()!.getToken(), 'new-refresh');
    });

    test('includes ClientSecret when CognitoUser has a client secret',
        () async {
      Map<String, dynamic>? body;
      final mockClient = MockClient((request) async {
        body = json.decode(request.body) as Map<String, dynamic>;
        return http.Response(
          json.encode({
            'AuthenticationResult': {
              'AccessToken': sampleJwt,
              'IdToken': sampleJwt,
              'RefreshToken': 'r',
            },
          }),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      const secret = '01234567890123456789012345678901';
      final storage = TestCustomStorage('');
      final pool = CognitoUserPool(
        userPoolId,
        clientId,
        customClient: Client(region: 'ap-southeast-1', client: mockClient),
        storage: storage,
      );
      final user = CognitoUser(
        username,
        pool,
        clientSecret: secret,
        storage: storage,
      );

      await user.getTokensFromRefreshToken(CognitoRefreshToken('rt'));

      expect(body!['ClientSecret'], secret);
    });

    test('loads DeviceKey from storage when LastAuthUser is present', () async {
      Map<String, dynamic>? body;
      final mockClient = MockClient((request) async {
        body = json.decode(request.body) as Map<String, dynamic>;
        return http.Response(
          json.encode({
            'AuthenticationResult': {
              'AccessToken': sampleJwt,
              'IdToken': sampleJwt,
              'RefreshToken': 'r',
            },
          }),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final storage = TestCustomStorage('');
      final pool = CognitoUserPool(
        userPoolId,
        clientId,
        customClient: Client(region: 'ap-southeast-1', client: mockClient),
        storage: storage,
      );

      await storage.setItem(pool.lastUserKey, username);
      const deviceKeyKey =
          'CognitoIdentityServiceProvider.$clientId.$username.deviceKey';
      await storage.setItem(deviceKeyKey, 'device-key-abc');

      final user = CognitoUser(username, pool, storage: storage);
      await user.getTokensFromRefreshToken(CognitoRefreshToken('rt'));

      expect(body!['DeviceKey'], 'device-key-abc');
    });

    test('passes ClientMetadata when provided', () async {
      Map<String, dynamic>? body;
      final mockClient = MockClient((request) async {
        body = json.decode(request.body) as Map<String, dynamic>;
        return http.Response(
          json.encode({
            'AuthenticationResult': {
              'AccessToken': sampleJwt,
              'IdToken': sampleJwt,
              'RefreshToken': 'r',
            },
          }),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final storage = TestCustomStorage('');
      final pool = CognitoUserPool(
        userPoolId,
        clientId,
        customClient: Client(region: 'ap-southeast-1', client: mockClient),
        storage: storage,
      );
      final user = CognitoUser(username, pool, storage: storage);

      await user.getTokensFromRefreshToken(
        CognitoRefreshToken('rt'),
        clientMetadata: {'k': 'v'},
      );

      expect(body!['ClientMetadata'], {'k': 'v'});
    });

    test('uses prior refresh token when response omits RefreshToken', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'AuthenticationResult': {
              'AccessToken': sampleJwt,
              'IdToken': sampleJwt,
            },
          }),
          200,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final storage = TestCustomStorage('');
      final pool = CognitoUserPool(
        userPoolId,
        clientId,
        customClient: Client(region: 'ap-southeast-1', client: mockClient),
        storage: storage,
      );
      final user = CognitoUser(username, pool, storage: storage);

      final session =
          await user.getTokensFromRefreshToken(CognitoRefreshToken('same-rt'));

      expect(session!.getRefreshToken()!.getToken(), 'same-rt');
    });

    test('clears cached tokens on NotAuthorizedException', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"__type":"NotAuthorizedException","message":"invalid"}',
          400,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final storage = TestCustomStorage('');
      final pool = CognitoUserPool(
        userPoolId,
        clientId,
        customClient: Client(region: 'ap-southeast-1', client: mockClient),
        storage: storage,
      );
      final user = CognitoUser(username, pool, storage: storage);
      const prefix = 'CognitoIdentityServiceProvider.$clientId.$username';
      await storage.setItem('$prefix.idToken', sampleJwt);
      await storage.setItem('$prefix.accessToken', sampleJwt);
      await storage.setItem('$prefix.refreshToken', 'cached-rt');
      await storage.setItem('$prefix.clockDrift', '0');
      await storage.setItem(pool.lastUserKey, username);

      await expectLater(
        user.getTokensFromRefreshToken(CognitoRefreshToken('rt')),
        throwsA(isA<CognitoClientException>()
            .having((e) => e.code, 'code', 'NotAuthorizedException')),
      );

      expect(await storage.getItem('$prefix.idToken'), isNull);
      expect(await storage.getItem('$prefix.refreshToken'), isNull);
      expect(await storage.getItem(pool.lastUserKey), isNull);
    });

    test('propagates RefreshTokenReuseException without clearing cache',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"__type":"RefreshTokenReuseException","message":"reuse"}',
          400,
          headers: {'Content-Type': 'application/json'},
        );
      });

      final storage = TestCustomStorage('');
      final pool = CognitoUserPool(
        userPoolId,
        clientId,
        customClient: Client(region: 'ap-southeast-1', client: mockClient),
        storage: storage,
      );
      final user = CognitoUser(username, pool, storage: storage);
      const prefix = 'CognitoIdentityServiceProvider.$clientId.$username';
      await storage.setItem('$prefix.refreshToken', 'cached-rt');

      await expectLater(
        user.getTokensFromRefreshToken(CognitoRefreshToken('rt')),
        throwsA(isA<CognitoClientException>()
            .having((e) => e.code, 'code', 'RefreshTokenReuseException')),
      );

      expect(await storage.getItem('$prefix.refreshToken'), isNotNull);
    });
  });
}
