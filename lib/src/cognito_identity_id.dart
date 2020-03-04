import 'dart:async';

import 'client.dart';
import 'cognito_user_pool.dart';

class CognitoIdentityId {
  String identityId;
  final String _identityPoolId;
  final String _userPoolId;
  final CognitoUserPool _pool;
  final Client _client;
  final String _region;
  final String _identityIdKey;

  CognitoIdentityId(this._identityPoolId, this._pool)
      : _userPoolId = _pool.getUserPoolId(),
        _region = _pool.getRegion(),
        _client = _pool.client,
        _identityIdKey = 'aws.cognito.identity-id.$_identityPoolId';

  /// Get AWS Identity Id for authenticated user
  Future<String> getIdentityId(token, [String authenticator]) async {
    authenticator ??= 'cognito-idp.$_region.amazonaws.com/$_userPoolId';
    final Map<String, String> loginParam = {
      authenticator: token,
    };

    return _getCognitoIdentityId(loginParam);
  }

  Future<String> getGuestIdentityId() async {
    return _getCognitoIdentityId();
  }

  Future<String> _getCognitoIdentityId([Map<String, String> loginParam]) async {
    String identityId = await _pool.storage.getItem(_identityIdKey);
    if (identityId != null) {
      this.identityId = identityId;
      return identityId;
    }

    final Map<String, dynamic> paramsReq = {'IdentityPoolId': _identityPoolId};

    if (loginParam != null) {
      paramsReq['Logins'] = loginParam;
    }

    final data = await _client.request('GetId', paramsReq,
        service: 'AWSCognitoIdentityService',
        endpoint: 'https://cognito-identity.$_region.amazonaws.com/');

    this.identityId = data['IdentityId'];
    await _pool.storage.setItem(_identityIdKey, this.identityId);

    return this.identityId;
  }

  /// Remove AWS Identity Id from storage
  Future<String> removeIdentityId() async {
    final identityIdKey = 'aws.cognito.identity-id.$_identityPoolId';
    return await _pool.storage.removeItem(identityIdKey);
  }
}
