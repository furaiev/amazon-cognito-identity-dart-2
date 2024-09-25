## 3.6.4
- added: optional Refresh Token revocation on sign-out

## 3.6.3
- added: secret hash in SMS MFA

## 3.6.2
- bumped: js from 0.6.7 to 0.7.0

## 3.6.1
- fixed: username assignment during _authenticateUserDefaultAuth in CognitoUser

## 3.6.0
- http dependency includes older 0.13.1 version as valid
- added: additional support for mfa functionalities

## 3.6.0-dev.1
- http dependency includes older 0.13.1 version as valid

## 3.5.0
- dependencies are updated to the latest

## 3.4.0
- fixed: SocketException when network is disabled

## 3.3.0
- changed: a specific exception `CognitoUserDeviceConfirmationNecessaryException` that can be handled whenever an users device needs confirmation is separated from `CognitoUserConfirmationNecessaryException`

## 3.2.0
- added: better handling of unverified phone numbers using sms mfa
- added: allow CUSTOM_AUTH authentication flow via SRP password verification

## 3.1.1
- fixed: CognitoUser.getSession throws TypeError when storage returns null for clockDrift

## 3.1.0
- feat: try to refresh session if access token is null

## 3.0.3
- fixed: clientSecret instead of client secret hash in refresh session

## 3.0.2
- added: secret hash to sendNewPasswordRequired function

## 3.0.1
- added: Regen SECRET_HASH using the srp username

## 3.0.0
- breaking: confirmRegistration forceAliasCreation parameter as named
- added: confirmRegistration clientMetadata parameter

## 2.1.3
- fixes: SECRET_HASH parameter in  `CognitoUser` `refreshSession()`

## 2.1.2
- adds: optional clientMetadata (Map<string,string>) to signup

## 2.1.1
- fixed: unexpected nullref during "initiateAuth" (authParameters is optional parameter in AuthenticationDetails)

## 2.1.0
- changed: SocketException detecting via pattern (removed dart:io dependency)

## 2.0.3
- added: flutter_test dev dependency

## 2.0.2
- added: flutter sdk dependency

## 2.0.1
- added: flutter dependency

## 2.0.0
- implement js BigInt workaround to speed up authenticateUser on flutter web
- deprecated pedantic replaced with flutter_lints + code style

## 1.0.5
- Changed: exports client.dart to facilitate using injection for automated testing

## 1.0.4
- Changed: SigV4Request headers is case insensitive

## 1.0.3
- Removed: Temporary workaround to BigInt.modPow

## 1.0.2
- Changed: challengeName as nullable variable

## 1.0.1
- Storage initialization fixes

## 1.0.0
- Nullsafety branch is merged with latest non-nullsafety changes

## 0.1.25+4
- Fixed: a storage key issue
- Fixed: broken lastAuthUser lookup in CognitoUser

## 0.1.25+3
- Fixed: a storage key issue
- Defined a local variable `srp_username`, in order to not override `user` value

## 1.0.0-nullsafety.3
- Fixed: example
- Fixed: Retrieving data from Storage as `FutureOr<String?>` breaks clients
- Define `shared_preferences` as actual dependency, remove private file `.flutter-plugins-dependencies` and change code to work with latest `http`

## 1.0.0-nullsafety.2
- Fixed: http.post Uri argument

## 1.0.0-nullsafety.1
- Added optional validationData parameter for `sendCustomChallengeAnswer`
- Fixed: http.post

## 1.0.0-nullsafety.0
- Initial null safety

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
