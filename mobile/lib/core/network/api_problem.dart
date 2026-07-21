class ApiFieldError {
  const ApiFieldError({
    required this.field,
    required this.code,
    required this.message,
  });

  factory ApiFieldError.fromJson(Map<String, dynamic> json) {
    return ApiFieldError(
      field: json['field'] as String? ?? '',
      code: json['code'] as String? ?? 'INVALID',
      message: json['message'] as String? ?? 'Invalid value.',
    );
  }

  final String field;
  final String code;
  final String message;
}

class ApiProblem {
  const ApiProblem({
    required this.title,
    required this.status,
    required this.code,
    this.type,
    this.detail,
    this.instance,
    this.correlationId,
    this.errors = const [],
  });

  factory ApiProblem.fromJson(Map<String, dynamic> json) {
    final rawErrors = json['errors'];
    return ApiProblem(
      type: json['type'] as String?,
      title: json['title'] as String? ?? 'Request failed',
      status: (json['status'] as num?)?.toInt() ?? 0,
      code: json['code'] as String? ?? 'UNKNOWN_ERROR',
      detail: json['detail'] as String?,
      instance: json['instance'] as String?,
      correlationId: json['correlationId'] as String?,
      errors: rawErrors is List
          ? rawErrors
                .whereType<Map>()
                .map(
                  (item) =>
                      ApiFieldError.fromJson(item.cast<String, dynamic>()),
                )
                .toList(growable: false)
          : const [],
    );
  }

  final String? type;
  final String title;
  final int status;
  final String code;
  final String? detail;
  final String? instance;
  final String? correlationId;
  final List<ApiFieldError> errors;
}
