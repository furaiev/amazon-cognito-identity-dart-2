import 'dart:convert';

class CognitoUserAttribute {
  String name;
  String value;

  CognitoUserAttribute({this.name, this.value});

  String getValue() {
    return value;
  }

  CognitoUserAttribute setValue(String value) {
    this.value = value;
    return this;
  }

  String getName() {
    return name;
  }

  CognitoUserAttribute setName(String name) {
    this.name = name;
    return this;
  }

  @override
  String toString() {
    var attributes = toJson();
    var encoded = json.encode(attributes);
    return encoded.toString();
  }

  Map<String, String> toJson() {
    return {
      'Name': name,
      'Value': value,
    };
  }
}
