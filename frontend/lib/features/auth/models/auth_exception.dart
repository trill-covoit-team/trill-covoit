class AuthException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  const AuthException({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() => message;
}
