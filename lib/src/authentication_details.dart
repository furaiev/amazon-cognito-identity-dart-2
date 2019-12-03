import 'attribute_arg.dart';

class AuthenticationDetails {
  String username;
  String password;
  Map<String, String> validationData;
  List<AttributeArg> authParameters;
  AuthenticationDetails({
    this.username,
    this.password,
    this.validationData,
    this.authParameters,
  });

  String getUsername() {
    return this.username;
  }

  String getPassword() {
    return this.password;
  }

  Map<String, String> getValidationData() {
    return this.validationData;
  }

  List<AttributeArg> getAuthParameters() {
    return this.authParameters;
  }
}
