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
