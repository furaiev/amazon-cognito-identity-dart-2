class CognitoRefreshToken {
  final String? token;
  CognitoRefreshToken([String? refreshToken]) : token = refreshToken;

  String? getToken() {
    return token;
  }
}
