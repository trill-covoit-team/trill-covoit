import 'package:trill_covoit/exceptions/api_exception.dart';

class AuthException extends ApiException {
  const AuthException({
    required super.message,
    required super.statusCode,
    super.errorCode,
  });
}
