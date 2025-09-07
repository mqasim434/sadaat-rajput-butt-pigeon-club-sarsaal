/// Base exception class for the application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() {
    return '$runtimeType: $message${code != null ? ' (Code: $code)' : ''}';
  }
}

/// Exception thrown when authentication fails
class AuthenticationException extends AppException {
  const AuthenticationException(
    String message, {
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);
}

/// Exception thrown when network operations fail
class NetworkException extends AppException {
  const NetworkException(String message, {String? code, dynamic originalError})
    : super(message, code: code, originalError: originalError);
}

/// Exception thrown when validation fails
class ValidationException extends AppException {
  const ValidationException(
    String message, {
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);
}

/// Exception thrown for general service errors
class ServiceException extends AppException {
  const ServiceException(String message, {String? code, dynamic originalError})
    : super(message, code: code, originalError: originalError);
}

/// Exception thrown when unauthorized access is attempted
class UnauthorizedException extends AppException {
  const UnauthorizedException(
    String message, {
    String? code,
    dynamic originalError,
  }) : super(message, code: code, originalError: originalError);
}

/// Exception thrown when a timeout occurs
class TimeoutException extends AppException {
  const TimeoutException(String message, {String? code, dynamic originalError})
    : super(message, code: code, originalError: originalError);
}

