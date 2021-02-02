import 'dart:async';

import 'package:amazon_cognito_identity_dart_2/src/params_decorators.dart';

import 'attribute_arg.dart';
import 'client.dart';
import 'cognito_storage.dart';
import 'cognito_user.dart';

class CognitoUserPoolData {
  CognitoUser user;
  bool userConfirmed;
  String userSub;
  CognitoUserPoolData(this.user, {this.userConfirmed, this.userSub});

  factory CognitoUserPoolData.fromData(
      CognitoUser user, Map<String, dynamic> parsedJson) {
    return CognitoUserPoolData(
      user,
      userConfirmed: parsedJson['UserConfirmed'] ?? false,
      userSub: parsedJson['UserSub'],
    );
  }
}

class CognitoUserPool {
  String _userPoolId;
  String _clientId;
  String _clientSecret;
  String _region;
  bool advancedSecurityDataCollectionFlag;
  Client client;
  CognitoStorage storage;
  String _userAgent;
  final ParamsDecorator _analyticsMetadataParamsDecorator;

  CognitoUserPool(
    String userPoolId,
    String clientId, {
    String clientSecret,
    String endpoint,
    Client customClient,
    String customUserAgent,
    this.storage,
    this.advancedSecurityDataCollectionFlag = true,
    ParamsDecorator analyticsMetadataParamsDecorator,
  }) : _analyticsMetadataParamsDecorator =
            analyticsMetadataParamsDecorator ?? NoOpsParamsDecorator() {
    _userPoolId = userPoolId;
    _clientId = clientId;
    _clientSecret = clientSecret;
    final regExp = RegExp(r'^[\w-]+_.+$');
    if (!regExp.hasMatch(userPoolId)) {
      throw ArgumentError('Invalid userPoolId format.');
    }
    _region = userPoolId.split('_')[0];
    _userAgent = customUserAgent;
    client = Client(region: _region, endpoint: endpoint, userAgent: _userAgent);

    if (customClient != null) {
      client = customClient;
    }

    storage =
        storage ?? (CognitoStorageHelper(CognitoMemoryStorage())).getStorage();
  }

  String getUserPoolId() {
    return _userPoolId;
  }

  String getClientId() {
    return _clientId;
  }

  String getRegion() {
    return _region;
  }

  Future<CognitoUser> getCurrentUser() async {
    final lastUserKey =
        'CognitoIdentityServiceProvider.$_clientId.LastAuthUser';

    final lastAuthUser = await storage.getItem(lastUserKey);
    if (lastAuthUser != null) {
      return CognitoUser(lastAuthUser, this,
          storage: storage,
          clientSecret: _clientSecret,
          deviceName: _userAgent,
          analyticsMetadataParamsDecorator: _analyticsMetadataParamsDecorator);
    }

    return null;
  }

  /// This method returns the encoded data string used for cognito advanced security feature.
  /// This would be generated only when developer has included the JS used for collecting the
  /// data on their client. Please refer to documentation to know more about using AdvancedSecurity
  /// features
  /// TODO: not supported at the moment
  String getUserContextData(String username) {
    return null;
  }

  /// Registers the user in the specified user pool and creates a
  /// user name, password, and user attributes.
  Future<CognitoUserPoolData> signUp(
    String username,
    String password, {
    List<AttributeArg> userAttributes,
    List<AttributeArg> validationData,
  }) async {
    final params = {
      'ClientId': _clientId,
      'Username': username,
      'Password': password,
      'UserAttributes': userAttributes,
      'ValidationData': validationData,
    };

    if (_clientSecret != null) {
      params['SecretHash'] = CognitoUser.calculateClientSecretHash(
          username, _clientId, _clientSecret);
    }

    final data = await client.request(
        'SignUp', await _analyticsMetadataParamsDecorator.call(params));
    if (data == null) {
      return null;
    }
    return CognitoUserPoolData.fromData(
      CognitoUser(username, this,
          storage: storage,
          clientSecret: _clientSecret,
          deviceName: _userAgent,
          analyticsMetadataParamsDecorator: _analyticsMetadataParamsDecorator),
      data,
    );
  }
}
