# Secure Counter

An example Flutter project for [Amazon Cognito Identity Dart](https://github.com/jonsaw/amazon-cognito-identity-dart).

## Reset to latest version of flutter

```bash
rm -rf ios; rm -rf android; rm -rf .dart_tool; rm -rf build; rm -rf .packages; rm -rf secure_counter_android.iml; rm -rf secure_counter.iml; rm -rf .flutter-plugins; rm -rf .flutter-plugins-dependencies; rm -rf .metadata; flutter create --org com.example --project-name secure_counter .

cd ios; pod install; cd ..

```

## Create lib/secrets.dart (Do not commit it aka add to .gitignore)

```dart
// Store this file as lib/secrets.dart
// Generate your own file using https://github.com/pal/simple-counter-server
import 'package:amazon_cognito_identity_dart_2/cognito.dart';

const cognitoUserPoolId = 'us-east-1_XXXXXXX';
const cognitoClientId = 'XXXXXXXXXXXXXXX';
const cognitoIdentityPoolId = 'us-east-1:XXXXX-XXXXX-XXXX-XXXX-XXXXXXXX';
const awsRegion = 'us-east-1';
const apiEndpoint = 'https://XXXXXXX.execute-api.us-east-1.amazonaws.com';

final userPool = CognitoUserPool(cognitoUserPoolId, cognitoClientId);

```

<p align="center">
  <img title="Cognito Dart Demo screenshot" src="https://user-images.githubusercontent.com/1572333/39953217-77967bda-55d9-11e8-940c-90c34f870cb6.png" height="400px">
</p>

For a sample implementation of a secure server using Cognito, see [Simple Counter server in Javascript](https://github.com/pal/simple-counter-server) or [Secure Counter Server in Go](https://github.com/jonsaw/example-secure-counter-server).

### Sign Up

<p align="center">
  <img title="Sign up screenshot" src="https://user-images.githubusercontent.com/1572333/39953218-7a1aa8d6-55d9-11e8-93ca-bc3525d66c92.png" height="400px">
</p>

### Confirm Account

<p align="center">
  <img title="Confirm account screenshot" src="https://user-images.githubusercontent.com/1572333/39953219-7a682b92-55d9-11e8-94e5-d6fc737b91e0.png" height="400px">
</p>

### Login

<p align="center">
  <img title="Login screenshot" src="https://user-images.githubusercontent.com/1572333/39953220-7ab56c18-55d9-11e8-80a0-51ab9d319280.png" height="400px">
</p>

### Secured Screen

<p align="center">
  <img title="Secured screen screenshot" src="https://user-images.githubusercontent.com/1572333/39953222-7b1bf6ae-55d9-11e8-90df-55b472bb08c3.png" height="400px">
</p>

## Getting Started

For help getting started with Flutter, view the online
[documentation](https://flutter.io/).
