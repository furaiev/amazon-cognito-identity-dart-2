class CognitoClientException implements Exception {
  final String message;
  final int? statusCode;
  final String code;
  final String? name;
  CognitoClientException(
    this.message, {
    required this.code,
    this.statusCode,
    this.name,
  });

  @override
  String toString() {
    return 'CognitoClientException{statusCode: $statusCode, code: $code, name: $name, message: $message}';
  }
}
