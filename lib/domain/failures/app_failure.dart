/// Unified error handling for the application
abstract class AppFailure implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  AppFailure({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppFailure: $message (code: $code)';
}

// ==== Authentication Failures ====
class AuthenticationFailure extends AppFailure {
  AuthenticationFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
  );
}

class NetworkFailure extends AppFailure {
  NetworkFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
  );
}

class SecurityFailure extends AppFailure {
  SecurityFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
  );
}

class StorageFailure extends AppFailure {
  StorageFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
  );
}

class EncryptionFailure extends AppFailure {
  EncryptionFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
  );
}

class UnexpectedFailure extends AppFailure {
  UnexpectedFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(
    message: message,
    code: code,
    originalError: originalError,
  );
}
