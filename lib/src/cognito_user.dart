import 'dart:async';
import 'dart:convert';

import 'package:amazon_cognito_identity_dart_2/src/params_decorators.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import 'authentication_details.dart';
import 'authentication_helper.dart';
import 'client.dart';
import 'cognito_access_token.dart';
import 'cognito_client_exceptions.dart';
import 'cognito_id_token.dart';
import 'cognito_refresh_token.dart';
import 'cognito_storage.dart';
import 'cognito_user_attribute.dart';
import 'cognito_user_exceptions.dart';
import 'cognito_user_pool.dart';
import 'cognito_user_session.dart';
import 'date_helper.dart';

class CognitoUserAuthResult {
  String? challengeName;
  String? session;
  dynamic authenticationResult;

  CognitoUserAuthResult({
    this.challengeName,
    this.session,
    this.authenticationResult,
  });
}

class IMfaSettings {
  final bool preferredMfa;
  final bool enabled;

  IMfaSettings({
    required this.preferredMfa,
    required this.enabled,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'PreferredMfa': preferredMfa,
      'Enabled': enabled,
    };
  }

  factory IMfaSettings.fromMap(Map<String, dynamic> map) {
    return IMfaSettings(
      preferredMfa: map['PreferredMfa'] as bool,
      enabled: map['Enabled'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory IMfaSettings.fromJson(String source) =>
      IMfaSettings.fromMap(json.decode(source) as Map<String, dynamic>);
}

class CognitoUser {
  String? _deviceKey;
  String? _randomPassword;
  String? _deviceGroupKey;
  String? _session;
  CognitoUserSession? _signInUserSession;
  String? email;
  String? username;
  String? _clientSecret;
  String? _clientSecretHash;
  CognitoUserPool pool;
  Client? client;
  String? authenticationFlowType;
  String? deviceName;
  String? verifierDevices;
  late CognitoStorage storage;
  final ParamsDecorator _analyticsMetadataParamsDecorator;

  CognitoUser(
    this.username,
    this.pool, {
    String? email,
    clientSecret,
    CognitoStorage? storage,
    this.deviceName = 'Dart-device',
    signInUserSession,
    ParamsDecorator? analyticsMetadataParamsDecorator,
  }) : _analyticsMetadataParamsDecorator =
            analyticsMetadataParamsDecorator ?? NoOpsParamsDecorator() {
    this.email = email ?? username;

    if (clientSecret != null) {
      _clientSecret = clientSecret;
      _clientSecretHash = calculateClientSecretHash(
        username!,
        pool.getClientId()!,
        _clientSecret!,
      );
    }
    if (signInUserSession != null) {
      _signInUserSession = signInUserSession;
    }
    client = pool.client;
    authenticationFlowType = 'USER_SRP_AUTH';

    this.storage = storage ??= pool.storage;
    pool.storage = this.storage;
  }

  String get keyPrefix =>
      'CognitoIdentityServiceProvider.${pool.getClientId()}.$email';

  Future<CognitoUserSession?> _authenticateUserInternal(
      dataAuthenticate, AuthenticationHelper authenticationHelper) async {
    final String? challengeName = dataAuthenticate['ChallengeName'];

    var challengeParameters = dataAuthenticate['ChallengeParameters'];

    if (challengeName == 'SMS_MFA') {
      _session = dataAuthenticate['Session'];
      throw CognitoUserMfaRequiredException(
          challengeName: challengeName,
          challengeParameters: challengeParameters);
    }

    if (challengeName == 'SELECT_MFA_TYPE') {
      _session = dataAuthenticate['Session'];
      throw CognitoUserSelectMfaTypeException(
          challengeName: challengeName,
          challengeParameters: challengeParameters);
    }

    if (challengeName == 'MFA_SETUP') {
      _session = dataAuthenticate['Session'];
      throw CognitoUserMfaSetupException(
          challengeName: challengeName,
          challengeParameters: challengeParameters);
    }

    if (challengeName == 'SOFTWARE_TOKEN_MFA') {
      _session = dataAuthenticate['Session'];
      throw CognitoUserTotpRequiredException(
          challengeName: challengeName,
          challengeParameters: challengeParameters);
    }

    if (challengeName == 'EMAIL_OTP') {
      _session = dataAuthenticate['Session'];
      throw CognitoUserEmailOtpRequiredException(
          challengeName: challengeName,
          challengeParameters: challengeParameters);
    }

    if (challengeName == 'CUSTOM_CHALLENGE') {
      _session = dataAuthenticate['Session'];
      throw CognitoUserCustomChallengeException(
          challengeName: challengeName,
          challengeParameters: challengeParameters);
    }

    if (challengeName == 'NEW_PASSWORD_REQUIRED') {
      _session = dataAuthenticate['Session'];
      dynamic userAttributes;
      List<dynamic>? requiredAttributes = [];
      if (challengeParameters['userAttributes'] != null) {
        userAttributes = json.decode(challengeParameters['userAttributes']);
        requiredAttributes = json.decode(
          challengeParameters['requiredAttributes'],
        );
      }
      throw CognitoUserNewPasswordRequiredException(
        userAttributes: userAttributes,
        requiredAttributes: requiredAttributes,
      );
    }

    if (challengeName == 'DEVICE_SRP_AUTH') {
      await getDeviceResponse();
      return _signInUserSession;
    }
    _signInUserSession =
        getCognitoUserSession(dataAuthenticate['AuthenticationResult']);
    await cacheTokens();

    final newDeviceMetadata =
        dataAuthenticate['AuthenticationResult']['NewDeviceMetadata'];
    if (newDeviceMetadata == null) {
      return _signInUserSession;
    }

    authenticationHelper.generateHashDevice(
      dataAuthenticate['AuthenticationResult']['NewDeviceMetadata']
          ['DeviceGroupKey'],
      dataAuthenticate['AuthenticationResult']['NewDeviceMetadata']
          ['DeviceKey'],
    );

    final deviceSecretVerifierConfig = {
      'Salt': base64.encode(hex.decode(authenticationHelper.getSaltDevices()!)),
      'PasswordVerifier':
          base64.encode(hex.decode(authenticationHelper.getVerifierDevices()!))
    };

    verifierDevices = deviceSecretVerifierConfig['PasswordVerifier'];
    _deviceGroupKey = newDeviceMetadata['DeviceGroupKey'];
    _randomPassword = authenticationHelper.getRandomPassword();

    final paramsConfirmDevice = {
      'DeviceKey': newDeviceMetadata['DeviceKey'],
      'AccessToken': _signInUserSession!.getAccessToken().getJwtToken(),
      'DeviceSecretVerifierConfig': deviceSecretVerifierConfig,
      'DeviceName': deviceName,
    };

    final dataConfirm =
        await client!.request('ConfirmDevice', paramsConfirmDevice);

    _deviceKey = dataAuthenticate['AuthenticationResult']['NewDeviceMetadata']
        ['DeviceKey'];
    await cacheDeviceKeyAndPassword();

    if (dataConfirm['UserConfirmationNecessary'] == true) {
      throw CognitoUserConfirmationNecessaryException(
          signInUserSession: _signInUserSession);
    }
    return _signInUserSession;
  }

  /// This is used to get a session, either from the session object
  /// or from  the local storage, or by using a refresh token
  Future<CognitoUserSession?> getSession() async {
    if (username == null) {
      throw Exception('Username is null. Cannot retrieve a new session');
    }

    if (_signInUserSession != null && _signInUserSession!.isValid()) {
      return _signInUserSession;
    }

    final idTokenKey = '$keyPrefix.idToken';
    final accessTokenKey = '$keyPrefix.accessToken';
    final refreshTokenKey = '$keyPrefix.refreshToken';
    final clockDriftKey = '$keyPrefix.clockDrift';

    final refreshTokenValue = await storage.getItem(refreshTokenKey);
    final refreshToken = CognitoRefreshToken(refreshTokenValue);
    final canRefreshToken = refreshToken.getToken() != null;

    final clockDriftValue = await storage.getItem(clockDriftKey);
    final clockDrift = int.tryParse(clockDriftValue ?? '');

    final idTokenValue = await storage.getItem(idTokenKey);
    if (idTokenValue == null) {
      if (canRefreshToken) {
        return refreshSession(refreshToken);
      }
      throw Exception(
          'Local storage is missing an ID Token, Please authenticate');
    }
    final idToken = CognitoIdToken(idTokenValue);

    final accessTokenValue = await storage.getItem(accessTokenKey);
    if (accessTokenValue == null) {
      if (canRefreshToken) {
        return refreshSession(refreshToken);
      }
      throw Exception(
          'Local storage is missing an Access Token, Please authenticate');
    }
    final accessToken = CognitoAccessToken(accessTokenValue);

    final cachedSession = CognitoUserSession(
      idToken,
      accessToken,
      refreshToken: refreshToken,
      clockDrift: clockDrift,
    );

    if (cachedSession.isValid()) {
      _signInUserSession = cachedSession;
      return _signInUserSession;
    }

    if (canRefreshToken) {
      return refreshSession(refreshToken);
    }

    throw Exception('Cannot retrieve a new session. Please authenticate.');
  }

  /// This is used to initiate an attribute confirmation request
  Future getAttributeVerificationCode(String attributeName) async {
    _signInUserSessionCheck();

    final paramsReq = {
      'AttributeName': attributeName,
      'AccessToken': _signInUserSession!.getAccessToken().getJwtToken(),
    };

    return await client!.request('GetUserAttributeVerificationCode', paramsReq);
  }

  /// This is used to confirm an attribute using a confirmation code
  Future<bool> verifyAttribute(attributeName, confirmationCode) async {
    _signInUserSessionCheck();

    final paramsReq = {
      'AttributeName': attributeName,
      'Code': confirmationCode,
      'AccessToken': _signInUserSession!.getAccessToken().getJwtToken(),
    };
    await client!.request('VerifyUserAttribute', paramsReq);

    return true;
  }

  /// This uses the refreshToken to retrieve a new session
  Future<CognitoUserSession?> refreshSession(
      CognitoRefreshToken refreshToken) async {
    final authParameters = {
      'REFRESH_TOKEN': refreshToken.getToken(),
    };

    final lastUsername = await storage.getItem(pool.lastUserUsernameKey);
    final lastEmail = await storage.getItem(pool.lastUserEmailKey);

    if (lastUsername != null && lastEmail != null) {
      username = lastUsername;
      email = lastEmail;
      final deviceKeyKey = '$keyPrefix.deviceKey';
      _deviceKey = await storage.getItem(deviceKeyKey);
      authParameters['DEVICE_KEY'] = _deviceKey;
    }

    if (_clientSecret != null) {
      authParameters['SECRET_HASH'] = _clientSecret;
    }

    final paramsReq = {
      'ClientId': pool.getClientId(),
      'AuthFlow': 'REFRESH_TOKEN_AUTH',
      'AuthParameters': authParameters,
    };
    if (getUserContextData() != null) {
      paramsReq['UserContextData'] = getUserContextData();
    }

    dynamic authResult;
    try {
      authResult = await client!.request('InitiateAuth',
          await _analyticsMetadataParamsDecorator.call(paramsReq));
    } on CognitoClientException catch (e) {
      if (e.code == 'NotAuthorizedException') {
        await clearCachedTokens();
      }
      rethrow;
    }

    if (authResult != null) {
      final authenticationResult = authResult['AuthenticationResult'];
      if (authenticationResult['RefreshToken'] == null) {
        authenticationResult['RefreshToken'] = refreshToken.getToken();
      }
      _signInUserSession = getCognitoUserSession(authenticationResult);
      await cacheTokens();
      return _signInUserSession;
    }
    return null;
  }

  CognitoUserSession? getSignInUserSession() {
    return _signInUserSession;
  }

  String? getUsername() {
    return username;
  }

  /// Returns the cached key for this device. Device keys are stored in local storage and are used to track devices.
  /// Returns `null` if no device key was cached.
  Future<String?> getDeviceKey() async {
    // Return device key if it has been loaded or updated
    if (_deviceKey != null) {
      return _deviceKey;
    }
    // Otherwise, load from local storage
    await getCachedDeviceKeyAndPassword();
    return _deviceKey;
  }

  String? getAuthenticationFlowType() {
    return authenticationFlowType;
  }

  /// sets authentication flow type
  void setAuthenticationFlowType(String authenticationFlowType) {
    this.authenticationFlowType = authenticationFlowType;
  }

  Future<void> getCachedDeviceKeyAndPassword() async {
    final deviceKeyKey = '$keyPrefix.deviceKey';
    final randomPasswordKey = '$keyPrefix.randomPasswordKey';
    final deviceGroupKeyKey = '$keyPrefix.deviceGroupKey';

    if (await storage.getItem(deviceKeyKey) != null) {
      _deviceKey = await storage.getItem(deviceKeyKey);
      _deviceGroupKey = await storage.getItem(deviceGroupKeyKey);
      _randomPassword = await storage.getItem(randomPasswordKey);
    }
  }

  /// This returns the user context data for advanced security feature.
  String? getUserContextData() {
    return pool.getUserContextData(username);
  }

  /// This is used to build a user session from tokens retrieved in the authentication result
  CognitoUserSession getCognitoUserSession(Map<String, dynamic> authResult) {
    final idToken = CognitoIdToken(authResult['IdToken']);
    final accessToken = CognitoAccessToken(authResult['AccessToken']);
    final refreshToken = CognitoRefreshToken(authResult['RefreshToken']);

    return CognitoUserSession(idToken, accessToken, refreshToken: refreshToken);
  }

  /// This is used to get a session using device authentication. It is called at the end of user
  /// authentication
  Future<CognitoUserSession?> getDeviceResponse() async {
    final authenticationHelper = AuthenticationHelper(_deviceGroupKey);
    final dateHelper = DateHelper();

    final authParameters = {
      'USERNAME': username,
      'DEVICE_KEY': _deviceKey,
    };
    final aValue = authenticationHelper.getLargeAValue()!;
    authParameters['SRP_A'] = aValue.toRadixString(16);
    if (_clientSecretHash != null) {
      authParameters['SECRET_HASH'] = _clientSecretHash;
    }

    final params = {
      'ChallengeName': 'DEVICE_SRP_AUTH',
      'ClientId': pool.getClientId(),
      'ChallengeResponses': authParameters,
    };

    if (getUserContextData() != null) {
      params['UserContextData'] = getUserContextData();
    }

    final data = await client!.request('RespondToAuthChallenge',
        await _analyticsMetadataParamsDecorator.call(params));
    final challengeParameters = data['ChallengeParameters'];
    final serverBValue = BigInt.parse(challengeParameters['SRP_B'], radix: 16);
    final saltString =
        authenticationHelper.toUnsignedHex(challengeParameters['SALT']);
    final salt = BigInt.parse(saltString, radix: 16);

    final hkdf = authenticationHelper.getPasswordAuthenticationKey(
        _deviceKey, _randomPassword, serverBValue, salt);

    final dateNow = dateHelper.getNowString();

    final signature = Hmac(sha256, hkdf);
    final signatureData = <int>[];
    signatureData
      ..addAll(utf8.encode(_deviceGroupKey!))
      ..addAll(utf8.encode(_deviceKey!))
      ..addAll(base64.decode(challengeParameters['SECRET_BLOCK']))
      ..addAll(utf8.encode(dateNow));
    final dig = signature.convert(signatureData);
    final signatureString = base64.encode(dig.bytes);

    final challengeResponses = {
      'USERNAME': username,
      'PASSWORD_CLAIM_SECRET_BLOCK': challengeParameters['SECRET_BLOCK'],
      'TIMESTAMP': dateNow,
      'PASSWORD_CLAIM_SIGNATURE': signatureString,
      'DEVICE_KEY': _deviceKey,
    };

    if (_clientSecretHash != null) {
      challengeResponses['SECRET_HASH'] = _clientSecretHash;
    }

    final paramsResp = {
      'ChallengeName': 'DEVICE_PASSWORD_VERIFIER',
      'ClientId': pool.getClientId(),
      'ChallengeResponses': challengeResponses,
      'Session': data['Session'],
    };

    if (getUserContextData() != null) {
      paramsResp['UserContextData'] = getUserContextData();
    }

    final dataAuthenticate = await client!.request('RespondToAuthChallenge',
        await _analyticsMetadataParamsDecorator.call(paramsResp));

    _signInUserSession =
        getCognitoUserSession(dataAuthenticate['AuthenticationResult']);
    await cacheTokens();
    return _signInUserSession;
  }

  /// This is used for authenticating the user through the custom authentication flow.
  Future<CognitoUserSession?> initiateAuth(
      AuthenticationDetails authDetails) async {
    final authParameters = (authDetails.getAuthParameters() ?? []).fold({},
        (dynamic value, element) {
      value[element.name] = element.value;
      return value;
    });
    authParameters['USERNAME'] = username;

    if (_clientSecretHash != null) {
      authParameters['SECRET_HASH'] = _clientSecretHash;
    }

    final paramsReq = {
      'AuthFlow': 'CUSTOM_AUTH',
      'ClientId': pool.getClientId(),
      'AuthParameters': authParameters,
      'ClientMetadata': authDetails.getValidationData(),
    };

    if (getUserContextData() != null) {
      paramsReq['UserContextData'] = getUserContextData();
    }

    final data = await client!.request('InitiateAuth',
        await _analyticsMetadataParamsDecorator.call(paramsReq));

    final String? challengeName = data['ChallengeName'];
    final challengeParameters = data['ChallengeParameters'];
    if (challengeName == 'CUSTOM_CHALLENGE') {
      _session = data['Session'];
      throw CognitoUserCustomChallengeException(
          challengeParameters: challengeParameters);
    }

    _signInUserSession = getCognitoUserSession(data['AuthenticationResult']);
    await cacheTokens();

    return _signInUserSession;
  }

  /// This is used for authenticating the user.
  Future<CognitoUserSession?> authenticateUser(
      AuthenticationDetails authDetails) async {
    if (authenticationFlowType == 'USER_PASSWORD_AUTH') {
      return await _authenticateUserPlainUsernamePassword(authDetails);
    } else if (authenticationFlowType == 'USER_SRP_AUTH' ||
        authenticationFlowType == 'CUSTOM_AUTH') {
      return await _authenticateUserDefaultAuth(authDetails);
    }
    throw UnimplementedError('Authentication flow type is not supported.');
  }

  /// This is used for the user to signOut of the application and clear the cached tokens.
  /// If `revokeRefreshToken` is set to true, it will revoke the refresh token.
  Future<void> signOut({bool revokeRefreshToken = false}) async {
    if (revokeRefreshToken && _signInUserSession != null) {
      final paramsReq = {
        'ClientId': pool.getClientId(),
        'Token': _signInUserSession!.getRefreshToken()!.getToken(),
      };
      if (_clientSecret != null) {
        paramsReq['ClientSecret'] = _clientSecret;
      }
      await client!.request('RevokeToken', paramsReq);
    }
    _signInUserSession = null;
    await clearCachedTokens();
  }

  /// This is used to globally revoke all tokens issued to a user
  Future<void> globalSignOut() async {
    _signInUserSessionCheck();

    final paramsReq = {
      'AccessToken': _signInUserSession!.getAccessToken().getJwtToken(),
    };
    await client!.request('GlobalSignOut', paramsReq);
    await clearCachedTokens();
  }

  Future<CognitoUserSession?> _authenticateUserPlainUsernamePassword(
      AuthenticationDetails authDetails) async {
    final authParameters = {
      'USERNAME': username,
      'PASSWORD': authDetails.getPassword(),
    };
    if (_clientSecretHash != '') {
      authParameters['SECRET_HASH'] = _clientSecretHash;
    }
    if (authParameters['PASSWORD'] == null) {
      throw ArgumentError('PASSWORD parameter is required');
    }

    final authenticationHelper = AuthenticationHelper(
      pool.getUserPoolId().split('_')[1],
    );

    await getCachedDeviceKeyAndPassword();
    if (_deviceKey != null) {
      authParameters['DEVICE_KEY'] = _deviceKey;
    }

    final paramsReq = {
      'AuthFlow': 'USER_PASSWORD_AUTH',
      'ClientId': pool.getClientId(),
      'AuthParameters': authParameters,
      'ClientMetadata': authDetails.getValidationData(),
    };

    if (getUserContextData() != null) {
      paramsReq['UserContextData'] = getUserContextData();
    }
    final authResult = await client!.request('InitiateAuth',
        await _analyticsMetadataParamsDecorator.call(paramsReq));

    return _authenticateUserInternal(authResult, authenticationHelper);
  }

  Future<CognitoUserSession?> _authenticateUserDefaultAuth(
    AuthenticationDetails authDetails,
  ) async {
    final authenticationHelper = AuthenticationHelper(
      pool.getUserPoolId().split('_')[1],
    );
    final dateHelper = DateHelper();
    BigInt serverBValue;
    String saltString;
    BigInt salt;

    final authParameters = {};
    await getCachedDeviceKeyAndPassword();
    if (_deviceKey != null) {
      authParameters['DEVICE_KEY'] = _deviceKey;
    }
    authParameters['USERNAME'] = username;

    final srpA = authenticationHelper.getLargeAValue()!;
    authParameters['SRP_A'] = srpA.toRadixString(16);

    if (authenticationFlowType == 'CUSTOM_AUTH') {
      authParameters['CHALLENGE_NAME'] = 'SRP_A';
    }

    if (_clientSecretHash != null) {
      authParameters['SECRET_HASH'] = _clientSecretHash;
    }

    final params = {
      'AuthFlow': authenticationFlowType,
      'ClientId': pool.getClientId(),
      'AuthParameters': authParameters,
      'ClientMetadata': authDetails.getValidationData(),
    };

    if (getUserContextData() != null) {
      params['UserContextData'] = getUserContextData();
    }

    dynamic data;
    try {
      data = await client!.request(
          'InitiateAuth', await _analyticsMetadataParamsDecorator.call(params));
    } on CognitoClientException catch (e) {
      if (e.name == 'UserNotConfirmedException') {
        throw CognitoUserConfirmationNecessaryException();
      } else {
        rethrow;
      }
    } catch (e) {
      rethrow;
    }

    final challengeParameters = data['ChallengeParameters'];

    String srpUsername = challengeParameters['USER_ID_FOR_SRP'];
    if (username != srpUsername) {
      username = srpUsername;
    }
    serverBValue = BigInt.parse(challengeParameters['SRP_B'], radix: 16);
    saltString =
        authenticationHelper.toUnsignedHex(challengeParameters['SALT']);
    salt = BigInt.parse(saltString, radix: 16);

    var hkdf = authenticationHelper.getPasswordAuthenticationKey(
      srpUsername,
      authDetails.getPassword(),
      serverBValue,
      salt,
    );

    final dateNow = dateHelper.getNowString();

    final signature = Hmac(sha256, hkdf);
    final signatureData = <int>[];
    signatureData
      ..addAll(utf8.encode(pool.getUserPoolId().split('_')[1]))
      ..addAll(utf8.encode(srpUsername))
      ..addAll(base64.decode(challengeParameters['SECRET_BLOCK']))
      ..addAll(utf8.encode(dateNow));
    final dig = signature.convert(signatureData);
    final signatureString = base64.encode(dig.bytes);

    final challengeResponses = {
      'USERNAME': srpUsername,
      'PASSWORD_CLAIM_SECRET_BLOCK': challengeParameters['SECRET_BLOCK'],
      'TIMESTAMP': dateNow,
      'PASSWORD_CLAIM_SIGNATURE': signatureString,
    };

    if (_deviceKey != null) {
      challengeResponses['DEVICE_KEY'] = _deviceKey;
    }

    if (_clientSecretHash != null) {
      // Update client hash with the response from the auth challenge
      _clientSecretHash = calculateClientSecretHash(
        srpUsername,
        pool.getClientId()!,
        _clientSecret!,
      );

      challengeResponses['SECRET_HASH'] = _clientSecretHash;
    }

    Future<dynamic> respondToAuthChallenge(challenge) async {
      dynamic dataChallenge;
      try {
        dataChallenge =
            await client!.request('RespondToAuthChallenge', challenge);
      } on CognitoClientException catch (e) {
        if (e.code == 'ResourceNotFoundException' &&
            e.message!.toLowerCase().contains('device')) {
          challengeResponses['DEVICE_KEY'] = null;
          _deviceKey = null;
          _randomPassword = null;
          _deviceGroupKey = null;
          await clearCachedDeviceKeyAndPassword();
          return await respondToAuthChallenge(challenge);
        }
        rethrow;
      } catch (e) {
        rethrow;
      }
      return dataChallenge;
    }

    final jsonReqResp = {
      'ChallengeName': 'PASSWORD_VERIFIER',
      'ClientId': pool.getClientId(),
      'ChallengeResponses': challengeResponses,
      'Session': data['Session'],
      'ClientMetadata': authDetails.getValidationData(),
    };

    if (getUserContextData() != null) {
      jsonReqResp['UserContextData'] = getUserContextData();
    }

    final dataAuthenticate = await respondToAuthChallenge(
        await _analyticsMetadataParamsDecorator.call(jsonReqResp));

    final challengeName = dataAuthenticate['ChallengeName'];
    if (challengeName == 'NEW_PASSWORD_REQUIRED') {
      _session = dataAuthenticate['Session'];
      dynamic userAttributes;
      dynamic rawRequiredAttributes;
      final requiredAttributes = [];
      final userAttributesPrefix = authenticationHelper
          .getNewPasswordRequiredChallengeUserAttributePrefix();

      if (dataAuthenticate['ChallengeParameters'] != null) {
        userAttributes = json
            .decode(dataAuthenticate['ChallengeParameters']['userAttributes']);
        rawRequiredAttributes = json.decode(
            dataAuthenticate['ChallengeParameters']['requiredAttributes']);
      }

      if (rawRequiredAttributes != null) {
        rawRequiredAttributes.forEach((attribute) {
          requiredAttributes
              .add(attribute.substring(userAttributesPrefix.length));
        });
      }

      throw CognitoUserNewPasswordRequiredException(
          userAttributes: userAttributes,
          requiredAttributes: requiredAttributes);
    }
    return _authenticateUserInternal(dataAuthenticate, authenticationHelper);
  }

  ///
  /// Translated from library `aws-android-sdk-cognitoprovider@2.6.30` file `CognitoSecretHash.java::getSecretHash()`
  ///
  static String calculateClientSecretHash(
      String userName, String clientId, String clientSecret) {
    final hmac = Hmac(sha256, utf8.encode(clientSecret));
    final digest = hmac.convert(utf8.encode(userName + clientId));
    hmac.convert(digest.bytes);
    return base64.encode(digest.bytes);
  }

  /// This is used for a certain user to confirm the registration by using a confirmation code
  Future<bool> confirmRegistration(String confirmationCode,
      {bool forceAliasCreation = false,
      Map<String, String>? clientMetadata}) async {
    final params = {
      'ClientId': pool.getClientId(),
      'ConfirmationCode': confirmationCode,
      'Username': username,
      'ForceAliasCreation': forceAliasCreation,
      'ClientMetadata': clientMetadata
    };

    if (getUserContextData() != null) {
      params['UserContextData'] = getUserContextData();
    }

    if (_clientSecretHash != null) {
      params['SecretHash'] = _clientSecretHash;
    }

    await client!.request(
        'ConfirmSignUp', await _analyticsMetadataParamsDecorator.call(params));
    return true;
  }

  /// This is used by a user to resend a confirmation code
  dynamic resendConfirmationCode() async {
    final params = {
      'ClientId': pool.getClientId(),
      'Username': username,
    };

    if (_clientSecretHash != null) {
      params['SecretHash'] = _clientSecretHash;
    }

    var data = await client!.request('ResendConfirmationCode',
        await _analyticsMetadataParamsDecorator.call(params));

    return data;
  }

  /// This is used by the user once he has the responses to a custom challenge

  Future<CognitoUserSession?> sendCustomChallengeAnswer(String answerChallenge,
      [Map<String, String>? validationData]) async {
    final challengeResponses = {
      'USERNAME': username,
      'ANSWER': answerChallenge,
    };

    final authenticationHelper =
        AuthenticationHelper(pool.getUserPoolId().split('_')[1]);

    await getCachedDeviceKeyAndPassword();
    if (_deviceKey != null) {
      challengeResponses['DEVICE_KEY'] = _deviceKey;
    }

    if (_clientSecretHash != null) {
      challengeResponses['SECRET_HASH'] = _clientSecretHash;
    }

    final paramsReq = {
      'ChallengeName': 'CUSTOM_CHALLENGE',
      'ChallengeResponses': challengeResponses,
      'ClientId': pool.getClientId(),
      'ClientMetadata': validationData,
      'Session': _session,
    };

    if (getUserContextData() != null) {
      paramsReq['UserContextData'] = getUserContextData();
    }

    final data = await client!.request('RespondToAuthChallenge',
        await _analyticsMetadataParamsDecorator.call(paramsReq));

    return _authenticateUserInternal(data, authenticationHelper);
  }

  /// This is used by the user once he has the responses to the NEW_PASSWORD_REQUIRED challenge.
  ///
  /// Its allow set a new user password and optionally set new user attributes.
  /// Attributes can be send in the *requiredAttributes* map where a map key is an attribute
  /// name and a map value is an attribute value.
  Future<CognitoUserSession?> sendNewPasswordRequiredAnswer(String newPassword,
      [Map<String, String>? requiredAttributes]) async {
    final challengeResponses = {
      'USERNAME': username,
      'NEW_PASSWORD': newPassword,
    };

    if (requiredAttributes != null && requiredAttributes.isNotEmpty) {
      requiredAttributes.forEach((key, value) {
        challengeResponses['userAttributes.$key'] = value;
      });
    }

    final authenticationHelper =
        AuthenticationHelper(pool.getUserPoolId().split('_')[1]);

    await getCachedDeviceKeyAndPassword();
    if (_deviceKey != null) {
      challengeResponses['DEVICE_KEY'] = _deviceKey;
    }

    if (_clientSecretHash != null) {
      challengeResponses['SECRET_HASH'] = _clientSecretHash;
    }

    final paramsReq = {
      'ChallengeName': 'NEW_PASSWORD_REQUIRED',
      'ChallengeResponses': challengeResponses,
      'ClientId': pool.getClientId(),
      'Session': _session,
    };

    if (getUserContextData() != null) {
      paramsReq['UserContextData'] = getUserContextData();
    }

    final data = await client!.request('RespondToAuthChallenge',
        await _analyticsMetadataParamsDecorator.call(paramsReq));

    return _authenticateUserInternal(data, authenticationHelper);
  }

  /// This is used by the user once he has an MFA code
  Future<CognitoUserSession?> sendMFACode(String confirmationCode,
      [String mfaType = 'SMS_MFA']) async {
    final challengeResponses = {
      'USERNAME': username,
      'SMS_MFA_CODE': confirmationCode,
    };
    if (mfaType == 'SOFTWARE_TOKEN_MFA') {
      challengeResponses['SOFTWARE_TOKEN_MFA_CODE'] = confirmationCode;
    }
    if (mfaType == 'EMAIL_OTP') {
      challengeResponses['EMAIL_OTP_CODE'] = confirmationCode;
    }
    if (_clientSecretHash != null) {
      challengeResponses['SECRET_HASH'] = _clientSecretHash;
    }

    await getCachedDeviceKeyAndPassword();
    if (_deviceKey != null) {
      challengeResponses['DEVICE_KEY'] = _deviceKey;
    }

    final paramsReq = {
      'ChallengeName': mfaType,
      'ChallengeResponses': challengeResponses,
      'ClientId': pool.getClientId(),
      'Session': _session,
    };
    if (getUserContextData() != null) {
      paramsReq['UserContextData'] = getUserContextData();
    }

    dynamic dataAuthenticate;
    try {
      dataAuthenticate = await client!.request('RespondToAuthChallenge',
          await _analyticsMetadataParamsDecorator.call(paramsReq));
    } on CognitoClientException catch (e) {
      // When trying to use MFA with a non verified phone_number this
      // missleading error will be received because Cognito expects in this case
      // the GUID style user name instead of the normal user name used in every
      // other request.
      if (e.code == "UserNotFoundException") {
        throw CognitoUserPhoneNumberVerificationNecessaryException();
      } else {
        rethrow;
      }
    }

    final String? challengeName = dataAuthenticate['ChallengeName'];

    if (challengeName == 'DEVICE_SRP_AUTH') {
      return getDeviceResponse();
    }

    _signInUserSession =
        getCognitoUserSession(dataAuthenticate['AuthenticationResult']);
    await cacheTokens();

    if (dataAuthenticate['AuthenticationResult']['NewDeviceMetadata'] == null) {
      return _signInUserSession;
    }

    final authenticationHelper =
        AuthenticationHelper(pool.getUserPoolId().split('_')[1]);
    authenticationHelper.generateHashDevice(
        dataAuthenticate['AuthenticationResult']['NewDeviceMetadata']
            ['DeviceGroupKey'],
        dataAuthenticate['AuthenticationResult']['NewDeviceMetadata']
            ['DeviceKey']);

    final deviceSecretVerifierConfig = {
      'Salt': base64.encode(hex.decode(authenticationHelper.getSaltDevices()!)),
      'PasswordVerifier':
          base64.encode(hex.decode(authenticationHelper.getVerifierDevices()!)),
    };

    verifierDevices = deviceSecretVerifierConfig['PasswordVerifier'];
    _deviceGroupKey = dataAuthenticate['AuthenticationResult']
        ['NewDeviceMetadata']['DeviceGroupKey'];
    _randomPassword = authenticationHelper.getRandomPassword();

    final confirmDeviceParamsReq = {
      'DeviceKey': dataAuthenticate['AuthenticationResult']['NewDeviceMetadata']
          ['DeviceKey'],
      'AccessToken': _signInUserSession!.getAccessToken().getJwtToken(),
      'DeviceSecretVerifierConfig': deviceSecretVerifierConfig,
      'DeviceName': deviceName,
    };
    final dataConfirm =
        await client!.request('ConfirmDevice', confirmDeviceParamsReq);
    _deviceKey = dataAuthenticate['AuthenticationResult']['NewDeviceMetadata']
        ['DeviceKey'];
    await cacheDeviceKeyAndPassword();
    if (dataConfirm['UserConfirmationNecessary'] == true) {
      throw CognitoUserDeviceConfirmationNecessaryException(
          signInUserSession: _signInUserSession);
    }

    return _signInUserSession;
  }

  /// This is used by an authenticated user to change the current password
  Future<bool> changePassword(
      String oldUserPassword, String newUserPassword) async {
    if (!(_signInUserSession != null && _signInUserSession!.isValid())) {
      throw Exception('User is not authenticated');
    }

    final paramsReq = {
      'PreviousPassword': oldUserPassword,
      'ProposedPassword': newUserPassword,
      'AccessToken': _signInUserSession!.getAccessToken().getJwtToken(),
    };
    if (_clientSecretHash != null) {
      paramsReq['SecretHash'] = _clientSecretHash;
    }
    await client!.request('ChangePassword', paramsReq);

    return true;
  }

  /// This is used by authenticated users to enable SMS-MFA for him/herself.
  /// A verified phone number is required.
  Future<bool> enableMfa() async {
    _signInUserSessionCheck();

    bool phoneNumberVerified = false;
    final getUserParamsReq = {
      'AccessToken': _signInUserSession!.getAccessToken().getJwtToken(),
    };
    final userData = await client!.request('GetUser', getUserParamsReq);

    if (userData['UserAttributes'] != null) {
      dynamic userAttributes = userData['UserAttributes'];
      phoneNumberVerified = null !=
          userAttributes.firstWhere(
              (attribute) =>
                  attribute['Name'] == 'phone_number_verified' &&
                  attribute['Value'] == 'true', orElse: () {
            return null;
          });
    }

    if (!phoneNumberVerified) {
      throw CognitoUserPhoneNumberVerificationNecessaryException(
          signInUserSession: _signInUserSession);
    }

    final mfaOptions = [];
    final mfaEnabled = {
      'DeliveryMedium': 'SMS',
      'AttributeName': 'phone_number',
    };
    mfaOptions.add(mfaEnabled);

    final paramsReq = {
      'MFAOptions': mfaOptions,
      'AccessToken': _signInUserSession!.getAccessToken().getJwtToken(),
    };

    await client!.request('SetUserSettings', paramsReq);
    return true;
  }

  /// This is used by an authenticated user to disable MFA for him/herself
  Future<bool> disableMfa() async {
    _signInUserSessionCheck();

    final mfaOptions = [];

    final paramsReq = {
      'MFAOptions': mfaOptions,
      'AccessToken': _signInUserSession!.getAccessToken().getJwtToken(),
    };

    await client!.request('SetUserSettings', paramsReq);
    return true;
  }

  /// This is used by an authenticated user to get the MFAOptions
  Future<List?> getMFAOptions() async {
    if (!(_signInUserSession != null && _signInUserSession!.isValid())) {
      throw Exception('User is not authenticated');
    }

    final paramsReq = {
      'AccessToken': _signInUserSession!.getAccessToken().getJwtToken(),
    };
    final userData = await client!.request('GetUser', paramsReq);

    return userData['MFAOptions'];
  }

  /// This is used to initiate a forgot password request
  Future forgotPassword() async {
    final paramsReq = {
      'ClientId': pool.getClientId(),
      'Username': username,
    };
    if (_clientSecretHash != null) {
      paramsReq['SecretHash'] = _clientSecretHash;
    }
    if (getUserContextData() != null) {
      paramsReq['UserContextData'] = getUserContextData();
    }

    return await client!.request('ForgotPassword',
        await _analyticsMetadataParamsDecorator.call(paramsReq));
  }

  /// This is used to confirm a new password using a confirmation code
  Future<bool> confirmPassword(
      String confirmationCode, String newPassword) async {
    final paramsReq = {
      'ClientId': pool.getClientId(),
      'Username': username,
      'ConfirmationCode': confirmationCode,
      'Password': newPassword,
    };
    if (_clientSecretHash != null) {
      paramsReq['SecretHash'] = _clientSecretHash;
    }
    if (getUserContextData() != null) {
      paramsReq['UserContextData'] = getUserContextData();
    }

    await client!.request('ConfirmForgotPassword',
        await _analyticsMetadataParamsDecorator.call(paramsReq));
    return true;
  }

  /// This is used to save the session tokens to local storage
  Future<void> cacheTokens() async {
    final idTokenKey = '$keyPrefix.idToken';
    final accessTokenKey = '$keyPrefix.accessToken';
    final refreshTokenKey = '$keyPrefix.refreshToken';
    final clockDriftKey = '$keyPrefix.clockDrift';

    await Future.wait([
      storage.setItem(
          idTokenKey, _signInUserSession?.getIdToken().getJwtToken()),
      storage.setItem(
          accessTokenKey, _signInUserSession?.getAccessToken().getJwtToken()),
      storage.setItem(
          refreshTokenKey, _signInUserSession?.getRefreshToken()?.getToken()),
      storage.setItem(clockDriftKey, '${_signInUserSession?.getClockDrift()}'),
      storage.setItem(pool.lastUserUsernameKey, username),
      storage.setItem(pool.lastUserEmailKey, email),
    ]);
  }

  /// This is used to clear the session tokens from local storage
  Future<void> clearCachedTokens() async {
    final idTokenKey = '$keyPrefix.idToken';
    final accessTokenKey = '$keyPrefix.accessToken';
    final refreshTokenKey = '$keyPrefix.refreshToken';
    final clockDriftKey = '$keyPrefix.clockDrift';

    await Future.wait([
      storage.removeItem(idTokenKey),
      storage.removeItem(accessTokenKey),
      storage.removeItem(refreshTokenKey),
      storage.removeItem(clockDriftKey),
      storage.removeItem(pool.lastUserUsernameKey),
      storage.removeItem(pool.lastUserEmailKey),
    ]);
  }

  /// This is used to cache the device key and device group and device password
  Future<void> cacheDeviceKeyAndPassword() async {
    final deviceKeyKey = '$keyPrefix.deviceKey';
    final randomPasswordKey = '$keyPrefix.randomPasswordKey';
    final deviceGroupKeyKey = '$keyPrefix.deviceGroupKey';

    await Future.wait([
      storage.setItem(deviceKeyKey, _deviceKey),
      storage.setItem(randomPasswordKey, _randomPassword),
      storage.setItem(deviceGroupKeyKey, _deviceGroupKey),
    ]);
  }

  /// This is used to clear the device key info from local storage
  Future<void> clearCachedDeviceKeyAndPassword() async {
    final deviceKeyKey = '$keyPrefix.deviceKey';
    final randomPasswordKey = '$keyPrefix.randomPasswordKey';
    final deviceGroupKeyKey = '$keyPrefix.deviceGroupKey';

    await Future.wait([
      storage.removeItem(deviceKeyKey),
      storage.removeItem(randomPasswordKey),
      storage.removeItem(deviceGroupKeyKey),
    ]);
  }

  /// This is used by authenticated users to get a list of attributes
  Future<List<CognitoUserAttribute>?> getUserAttributes() async {
    if (!(_signInUserSession != null && _signInUserSession!.isValid())) {
      throw Exception('User is not authenticated');
    }

    final paramsReq = {
      'AccessToken': _signInUserSession!.getAccessToken().getJwtToken(),
    };
    final userData = await client!.request('GetUser', paramsReq);

    if (userData['UserAttributes'] == null) {
      return null;
    }

    final attributeList = <CognitoUserAttribute>[];
    userData['UserAttributes'].forEach((attr) {
      attributeList
          .add(CognitoUserAttribute(name: attr['Name'], value: attr['Value']));
    });
    return attributeList;
  }

  /// This is used by authenticated users to change a list of attributes
  /// If phone_number is changed it needs to be verified to be able to use it
  /// for MFA.
  Future<bool> updateAttributes(List<CognitoUserAttribute> attributes) async {
    _signInUserSessionCheck();

    final paramsReq = {
      'AccessToken': _signInUserSession!.getAccessToken().getJwtToken(),
      'UserAttributes': attributes,
    };
    await client!.request('UpdateUserAttributes', paramsReq);

    return true;
  }

  /// This is used by an authenticated user to delete a list of attributes
  Future<bool> deleteAttributes(List<String> attributeList) async {
    if (!(_signInUserSession != null && _signInUserSession!.isValid())) {
      throw Exception('User is not authenticated');
    }

    final paramsReq = {
      'AccessToken': _signInUserSession!.getAccessToken().getJwtToken(),
      'UserAttributeNames': attributeList,
    };
    await client!.request('DeleteUserAttributes', paramsReq);

    return true;
  }

  /// This is used by an authenticated user to delete him/herself
  Future<bool> deleteUser() async {
    _signInUserSessionCheck();

    final paramsReq = {
      'AccessToken': _signInUserSession!.getAccessToken().getJwtToken(),
    };
    await client!.request('DeleteUser', paramsReq);
    await clearCachedTokens();

    return true;
  }

  ///  This is used to associate a TOTP MFA
  Future<String?> associateSoftwareToken() async {
    if (_signInUserSession?.isValid() ?? false) {
      final data = await client!.request(
        'AssociateSoftwareToken',
        {'AccessToken': _signInUserSession!.getAccessToken().getJwtToken()},
      );

      return data['SecretCode'];
    } else if (_session != null) {
      final data = await client!.request(
        'AssociateSoftwareToken',
        {'Session': _session},
      );

      _session = data["Session"];

      return data['SecretCode'];
    }

    throw Exception("User is not authenticated");
  }

  /// This is used to verify a TOTP MFA
  Future<bool> verifySoftwareToken({
    required String totpCode,
    String? friendlyDeviceName,
  }) async {
    if (_signInUserSession?.isValid() ?? false) {
      final data = await client!.request('VerifySoftwareToken', {
        'AccessToken': _signInUserSession!.getAccessToken().getJwtToken(),
        'UserCode': totpCode,
        'FriendlyDeviceName': friendlyDeviceName ?? 'My TOTP device',
      });

      return data['Status'] == 'SUCCESS';
    } else if (_session != null) {
      final data = await client!.request('VerifySoftwareToken', {
        'Session': _session,
        'UserCode': totpCode,
        'FriendlyDeviceName': friendlyDeviceName ?? 'My TOTP device',
      });

      return data['Status'] == 'SUCCESS';
    }

    throw Exception("User is not authenticated");
  }

  /// This is used by an authenticated user to enable MFA for itself
  Future<bool> setUserMfaPreference(
    IMfaSettings? smsMfaSettings,
    IMfaSettings? softwareTokenMfaSettings,
  ) async {
    _signInUserSessionCheck();

    try {
      await client!.request('SetUserMFAPreference', {
        'SMSMfaSettings': smsMfaSettings?.toMap(),
        'SoftwareTokenMfaSettings': softwareTokenMfaSettings?.toMap(),
        'AccessToken': _signInUserSession?.getAccessToken().getJwtToken(),
      });
      return true;
    } catch (err) {
      return false;
    }
  }

  /// Set prefered MFA Method which can be one of the following 'SOFTWARE_TOKEN_MFA' | 'SMS_MFA' | 'NOMFA'
  Future<bool> setPreferredMFA(String mfaMethod) async {
    IMfaSettings? smsMfaSettings;
    IMfaSettings? softwareTokenMfaSettings;

    switch (mfaMethod) {
      case 'SOFTWARE_TOKEN_MFA':
        {
          softwareTokenMfaSettings =
              IMfaSettings(preferredMfa: true, enabled: true);
          break;
        }
      case 'SMS_MFA':
        {
          smsMfaSettings = IMfaSettings(preferredMfa: true, enabled: true);
          break;
        }
      case 'NOMFA':
        {
          smsMfaSettings = IMfaSettings(preferredMfa: false, enabled: false);
          softwareTokenMfaSettings =
              IMfaSettings(preferredMfa: false, enabled: false);
          break;
        }
      default:
        throw Exception('No valid MFA method provided');
    }

    return setUserMfaPreference(smsMfaSettings, softwareTokenMfaSettings);
  }

  /// This is used by an authenticated user to get the preferred MFA method
  Future<String?> getPreferredMFA() async {
    _signInUserSessionCheck();

    final userData = await client!.request(
      'GetUser',
      {
        'AccessToken': _signInUserSession!.getAccessToken().getJwtToken(),
      },
    );

    return userData['PreferredMfaSetting'];
  }

  /// This is used by an authenticated user to get the available MFA methods
  Future<String?> getUserMFASettingList() async {
    _signInUserSessionCheck();

    final userData = await client!.request(
      'GetUser',
      {
        'AccessToken': _signInUserSession!.getAccessToken().getJwtToken(),
      },
    );

    return userData['UserMFASettingList'];
  }

  void _signInUserSessionCheck() {
    if (_signInUserSession == null || !_signInUserSession!.isValid()) {
      throw Exception('User is not authenticated');
    }
  }
}
