import 'dart:convert';

class CognitoJwtToken {
  String jwtToken;
  var payload;
  CognitoJwtToken(String token) {
    jwtToken = token;
    payload = decodePayload();
  }

  String getJwtToken() {
    return jwtToken;
  }

  int getExpiration() {
    return payload['exp'] ?? 0;
  }

  int getIssuedAt() {
    return payload['iat'] ?? 0;
  }

  dynamic decodePayload() {
    var payload = jwtToken.split('.')[1];
    if (payload.length % 4 > 0) {
      payload =
          payload.padRight(payload.length + (4 - payload.length % 4), '=');
    }
    try {
      return json.decode(utf8.decode(base64.decode(payload)));
    } catch (err) {
      return {};
    }
  }
}
