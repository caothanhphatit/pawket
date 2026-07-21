import 'api_problem.dart';

sealed class ApiException implements Exception {
  const ApiException(this.message, {this.correlationId});

  final String message;
  final String? correlationId;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkException extends ApiException {
  const NetworkException(super.message);
}

class RequestCancelledException extends ApiException {
  const RequestCancelledException() : super('The request was cancelled.');
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message, {super.correlationId});
}

class ForbiddenException extends ApiException {
  const ForbiddenException(super.message, {super.correlationId});
}

class NotFoundException extends ApiException {
  const NotFoundException(super.message, {super.correlationId});
}

class ValidationException extends ApiException {
  const ValidationException(
    super.message, {
    required this.errors,
    super.correlationId,
  });

  final List<ApiFieldError> errors;
}

class ConflictException extends ApiException {
  const ConflictException(super.message, {super.correlationId});
}

class RateLimitException extends ApiException {
  const RateLimitException(
    super.message, {
    this.retryAfter,
    super.correlationId,
  });

  final Duration? retryAfter;
}

class ServerException extends ApiException {
  const ServerException(super.message, {super.correlationId});
}

class UnknownApiException extends ApiException {
  const UnknownApiException(super.message, {super.correlationId});
}
