class CognitoRefreshToken {
  String? token;
  CognitoRefreshToken([String? refreshToken = '']) {
    token = refreshToken;
  }

  String? getToken() {
    return token;
  }
}
