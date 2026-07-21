import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import 'api_exception.dart';
import 'api_problem.dart';

typedef AccessTokenProvider = FutureOr<String?> Function();

class ApiClient {
  ApiClient({
    required ApiConfig config,
    Dio? dio,
    Dio? uploadDio,
    this._accessTokenProvider,
  }) : _config = config,
       _dio = dio ?? Dio(),
       _uploadDio = uploadDio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      sendTimeout: config.sendTimeout,
      responseType: ResponseType.json,
      headers: const {'Accept': 'application/json'},
    );
  }

  final ApiConfig _config;
  final Dio _dio;

  // Signed storage URLs must not receive Pawket auth or identity headers.
  final Dio _uploadDio;
  final AccessTokenProvider? _accessTokenProvider;
  final Random _random = Random.secure();

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) {
    return _request<T>(
      'GET',
      path,
      queryParameters: queryParameters,
      cancelToken: cancelToken,
      retrySafe: true,
    );
  }

  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    String? idempotencyKey,
    CancelToken? cancelToken,
  }) {
    return _request<T>(
      'POST',
      path,
      data: data,
      queryParameters: queryParameters,
      idempotencyKey: idempotencyKey,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> put<T>(
    String path, {
    Object? data,
    String? idempotencyKey,
    CancelToken? cancelToken,
  }) {
    return _request<T>(
      'PUT',
      path,
      data: data,
      idempotencyKey: idempotencyKey,
      cancelToken: cancelToken,
    );
  }

  Uri resolveUri(Uri uri) {
    if (uri.hasScheme) return uri;
    return Uri.parse(_config.baseUrl).resolveUri(uri);
  }

  Future<Response<T>> patch<T>(
    String path, {
    Object? data,
    String? idempotencyKey,
    CancelToken? cancelToken,
  }) {
    return _request<T>(
      'PATCH',
      path,
      data: data,
      idempotencyKey: idempotencyKey,
      cancelToken: cancelToken,
    );
  }

  Future<Response<T>> delete<T>(
    String path, {
    Object? data,
    String? idempotencyKey,
    CancelToken? cancelToken,
  }) {
    return _request<T>(
      'DELETE',
      path,
      data: data,
      idempotencyKey: idempotencyKey,
      cancelToken: cancelToken,
    );
  }

  Future<void> uploadSignedUrl({
    required Uri url,
    required Object data,
    required String contentType,
    int? contentLength,
    Map<String, String> headers = const {},
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await _uploadDio.putUri<void>(
        url,
        data: data,
        options: Options(
          contentType: contentType,
          headers: {
            ...headers,
            if (!kIsWeb && contentLength != null)
              Headers.contentLengthHeader: contentLength,
          },
        ),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );
    } on DioException catch (error) {
      throw _mapDioException(error);
    }
  }

  Future<Response<T>> _request<T>(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    String? idempotencyKey,
    CancelToken? cancelToken,
    bool retrySafe = false,
  }) async {
    final headers = await _headers(idempotencyKey: idempotencyKey);
    const maxAttempts = 3;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await _dio.request<T>(
          path,
          data: data,
          queryParameters: queryParameters,
          options: Options(method: method, headers: headers),
          cancelToken: cancelToken,
        );
      } on DioException catch (error) {
        if (retrySafe && attempt < maxAttempts && _isTransient(error)) {
          final jitter = _random.nextInt(150);
          await Future<void>.delayed(
            Duration(milliseconds: 250 * (1 << (attempt - 1)) + jitter),
          );
          continue;
        }
        throw _mapDioException(error);
      }
    }
    throw const UnknownApiException('The request could not be completed.');
  }

  Future<Map<String, String>> _headers({String? idempotencyKey}) async {
    final token = await _accessTokenProvider?.call();
    final authorization = token == null || token.isEmpty
        ? null
        : 'Bearer $token';
    return {
      'X-Correlation-Id': _newCorrelationId(),
      'Authorization': ?authorization,
      'X-User-Id': ?_config.devUserId,
      'Idempotency-Key': ?idempotencyKey,
      'Content-Type': 'application/json',
    };
  }

  String _newCorrelationId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final random = List.generate(
      3,
      (_) => _random.nextInt(0x7fffffff).toRadixString(36),
    ).join();
    return '$timestamp-$random';
  }

  bool _isTransient(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return true;
    }
    final status = error.response?.statusCode;
    return status == 408 || status == 429 || (status != null && status >= 500);
  }

  ApiException _mapDioException(DioException error) {
    if (error.type == DioExceptionType.cancel) {
      return const RequestCancelledException();
    }
    if (error.response == null) {
      return const NetworkException(
        'Cannot reach Pawket. Check your connection and try again.',
      );
    }

    final response = error.response!;
    final problem = _readProblem(response.data, response.statusCode);
    final message = problem.detail ?? problem.title;
    return switch (response.statusCode) {
      400 || 422 => ValidationException(
        message,
        errors: problem.errors,
        correlationId: problem.correlationId,
      ),
      401 => UnauthorizedException(
        message,
        correlationId: problem.correlationId,
      ),
      403 => ForbiddenException(message, correlationId: problem.correlationId),
      404 => NotFoundException(message, correlationId: problem.correlationId),
      409 ||
      412 => ConflictException(message, correlationId: problem.correlationId),
      429 => RateLimitException(
        message,
        retryAfter: _retryAfter(response.headers.value('retry-after')),
        correlationId: problem.correlationId,
      ),
      final status when status != null && status >= 500 => ServerException(
        'Pawket is temporarily unavailable. Please try again.',
        correlationId: problem.correlationId,
      ),
      _ => UnknownApiException(message, correlationId: problem.correlationId),
    };
  }

  ApiProblem _readProblem(Object? data, int? status) {
    if (data is Map) {
      return ApiProblem.fromJson(data.cast<String, dynamic>());
    }
    return ApiProblem(
      title: 'Request failed',
      status: status ?? 0,
      code: 'HTTP_ERROR',
    );
  }

  Duration? _retryAfter(String? value) {
    final seconds = int.tryParse(value ?? '');
    return seconds == null ? null : Duration(seconds: seconds);
  }
}
