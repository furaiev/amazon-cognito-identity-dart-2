import 'cognito_user_session.dart';

class CognitoUserException implements Exception {
  String message;
  String challengeName;
  CognitoUserException([this.message]);

  @override
  String toString() {
    var messageString = '';
    if (challengeName != null) messageString += ' "$challengeName"';
    if (message != null) messageString += ' $message';
    if (messageString == '') return 'CognitoUserException';
    return 'CognitoUserException:$messageString';
  }
}

class CognitoUserNewPasswordRequiredException extends CognitoUserException {
  @override
  String message;
  dynamic userAttributes;
  List<dynamic> requiredAttributes;
  CognitoUserNewPasswordRequiredException(
      {this.userAttributes,
      this.requiredAttributes,
      this.message = 'New Password required'});
}

class CognitoUserMfaRequiredException extends CognitoUserException {
  @override
  String message;
  @override
  String challengeName;
  dynamic challengeParameters;
  CognitoUserMfaRequiredException(
      {this.challengeName = 'SMS_MFA', this.challengeParameters, this.message});
}

class CognitoUserSelectMfaTypeException extends CognitoUserException {
  @override
  String message;
  @override
  String challengeName;
  dynamic challengeParameters;
  CognitoUserSelectMfaTypeException(
      {this.challengeName = 'SELECT_MFA_TYPE',
      this.challengeParameters,
      this.message});
}

class CognitoUserMfaSetupException extends CognitoUserException {
  @override
  String message;
  @override
  String challengeName;
  dynamic challengeParameters;
  CognitoUserMfaSetupException(
      {this.challengeName = 'MFA_SETUP',
      this.challengeParameters,
      this.message});
}

class CognitoUserTotpRequiredException extends CognitoUserException {
  @override
  String message;
  @override
  String challengeName;
  dynamic challengeParameters;
  CognitoUserTotpRequiredException(
      {this.challengeName = 'SOFTWARE_TOKEN_MFA',
      this.challengeParameters,
      this.message});
}

class CognitoUserCustomChallengeException extends CognitoUserException {
  @override
  String message;
  @override
  String challengeName;
  dynamic challengeParameters;
  CognitoUserCustomChallengeException(
      {this.challengeName = 'CUSTOM_CHALLENGE',
      this.challengeParameters,
      this.message});
}

class CognitoUserConfirmationNecessaryException extends CognitoUserException {
  @override
  String message;
  CognitoUserSession signInUserSession;
  CognitoUserConfirmationNecessaryException(
      {this.signInUserSession, this.message = 'User Confirmation Necessary'});
}
