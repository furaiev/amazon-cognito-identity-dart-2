## 0.1.25+2
- Added optional validationData parameter for `sendCustomChallengeAnswer`

## 0.1.25+1
- Example update: check for InvalidPasswordException in signup screen

## 0.1.25
- [Issue #69] Solving "type '_InternalLinkedHashMap<String, String>' is not a subtype of type 'String' of 'value'" bug when ParamsDecorator receives a Map<String, String>.

## 0.1.24+2
- [Issue #103] Set confirmed to true when email or phone_number is verified

## 0.1.24+1
- [Issue #88] Update example to latest version of Flutter for iOS, Android and Web. Uses AndroidX now which solves this issue
- [Issue #81] Enable login for Flutter Web by upgrading shared_preferences dependency version
- Separate example into individual files, for easier re-use / copy and paste
- Add a lib/secrets.dart file to hold the aws secrets. That file is added to .gitignore
- Add quick start instructions in readme for compiling example. Does not include how to setup resources in AWS, but that is a pre-requiste the example working.
- Migrate from depricated RaisedButton to ElevatedButton in example

## 0.1.24
- [Issue #69] Adding await in the call to analyticsMetadataParamsDecorator in case some implementations need to include async modifier

## 0.1.23
- [Issue #69] Propagating analyticsMetadataParamsDecorator to CognitoUser from CognitoUserPool

## 0.1.22
- [Issue #69] Adding support for AnalyticsMetadata request parameter

## 0.1.21
- failed AWS request with specific character

## 0.1.20
- removed: `getLargeAValue` call on `AuthenticationHelper` initialization

## 0.1.19
- added: additional getters for CognitoJwtToken

## 0.1.18
- added: SecretHash to ConfirmSignUp/ResendConfirmationCode request parameters

## 0.1.17
- added: clear the cached clockDriftKey

## 0.1.16
- added: Using an app client secret with '_authenticateUserPlainUsernamePassword'

## 0.1.15
- fixed: CognitoUser.getCachedDeviceKeyAndPassword as a Future<void>
- removed flutter_test dev dependency

## 0.1.14
- added: CognitoUser.getDeviceKey method
- added documentation for client secret

## 0.1.13
- changed: CognitoUser.updateAttributes and CognitoUser.deleteAttributes return Future<bool>
- added: CognitoUser.getMFAOptions method

## 0.1.12+3
- fix: type list<dynamic> is not a subtype of type list<int>

## 0.1.12+2
- fix: getUserAttributes strict casting issue

## 0.1.12+1
- fix: type 'List<dynamic>' is not a subtype of type 'List<int>'

## 0.1.12
- allowed session to be passed to CognitoUser constructor and added federated sign in example to README

## 0.1.11
- added guest auth support
- code clearing

## 0.1.10
- cleanup for pedantic v1.9.0 lints
- fix: correct decoding application/json utf8 response
- user confirmation error rethrow

## 0.1.9
- added support for Cognito CUSTOM_AUTH flows with client secrets
- exposed IdentityId in cognito_credentials to upload to S3 user folder

## 0.1.8
- fixed salt with a negative sign in front of it

## 0.1.7
- added authenticator param to getAwsCredentials function to authenticate with third-party authentication method (e.g. Facebook, Google)
- removed keyword 'new' from the code

## 0.1.6+1
- readme update

## 0.1.6
- added client secret support that is missing since original JS SDK
- fixed the bug that made DEVICE_PASSWORD_VERIFIER for remembered device fail
- fixed a custom authentication flow serialization issue (authParameters is an object, not an array)

## 0.1.5+2
- fixed wrong behaviour with Get Requests

## 0.1.5+1
- readme update, code formatting

## 0.1.5
- response to the NEW_PASSWORD_REQUIRED challenge

## 0.1.4
- sign Up custom validationData reverted to List

## 0.1.3+1
- fixed link to repo

## 0.1.3
- fixed Sign Up custom validationData

## 0.1.2
- added custom Authorization header option

## 0.1.1
- minor changes (description, formatting)

## 0.1.0
- forked from unsupported https://github.com/jonsaw/amazon-cognito-identity-dart/tree/master
- fixed custom validationData

______________________________________________

## 0.0.22
- Fix empty canonical query string generation

## 0.0.21
- Convert SigV4 methods to static
- Expose SigV4Client generated values

## 0.0.19
- Upgrade test dependencies

## 0.0.18

- Add missing request `await`s

## 0.0.17

- `invalidateToken()` to invalidate existing user session
- CognitoClientException `toString` with error details

## 0.0.16

- Better client request exception handling

## 0.0.15+1

- Fix [Example App](https://github.com/jonsaw/amazon-cognito-identity-dart/tree/master/example) cached Identity Id

## 0.0.15

- Add `removeIdentityId()` to CognitoIdentityId
- Add `resetAwsCredentials()` to CognitoCredentials
- Fix cached Identity Id error

## 0.0.14

- Cognito User Exceptions extend `CognitoUserException`
- Add `CognitoUserException` toString helper

## 0.0.13

- Add `RandomString` helper

## 0.0.12

- Use bool `true` to represent 'SUCCESS'
- Add `forgotPassword()` to CognitoUser
- Add `confirmPassword()` to CognitoUser
- Add `enableMfa()` to CognitoUser
- Add `disableMfa()` to CognitoUser
- Add `getAttributeVerificationCode()` to CognitoUser
- Add `verifyAttribute()` to CognitoUser
- Add `deleteUser()` to CognitoUser

## 0.0.11+1

- Updated [Example App](https://github.com/jonsaw/amazon-cognito-identity-dart/tree/master/example) with persisted login sessions

## 0.0.11

- Store expiry time in Cognito Credentials instance

## 0.0.10+1

- Updated [Example App](https://github.com/jonsaw/amazon-cognito-identity-dart/tree/master/example) with Signed Requests to Lambda

## 0.0.10

- Fix SigV4 signature error

## 0.0.9+1

- Added [Example App](https://github.com/jonsaw/amazon-cognito-identity-dart/tree/master/example)

## 0.0.9

- Add `getUserAttributes()` to CognitoUser
- Add `updateAttributes()` to CognitoUser
- Add `deleteAttributes()` to CognitoUser

## 0.0.8

- renamed `Storage` to `CognitoStorage`

## 0.0.7

- simplify package load to single entry point `cognito.dart`

## 0.0.6

- Add signature v4 helper
- Fix endpoint follows region

## 0.0.5

- Add get AWS credentials for authenticated users

## 0.0.4

- Remove dart:io dependency

## 0.0.3

- Format code with dartfmt

## 0.0.2

- Add Custom Storage support

## 0.0.1

- Initial Release
