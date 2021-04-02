import 'attribute_arg.dart';

class AuthenticationDetails {
  String username;
  String password;
  Map<String, String> validationData;
  List<AttributeArg> authParameters;
  AuthenticationDetails({
    required this.username,
    required this.password,
    required this.validationData,
    required this.authParameters,
  });

  String getUsername() {
    return username;
  }

  String getPassword() {
    return password;
  }

  Map<String, String> getValidationData() {
    return validationData;
  }

  List<AttributeArg> getAuthParameters() {
    return authParameters;
  }
}
