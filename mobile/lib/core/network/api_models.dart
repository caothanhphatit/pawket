typedef JsonMap = Map<String, dynamic>;

JsonMap requireJsonMap(Object? value, {String context = 'response'}) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  throw FormatException('Expected a JSON object for $context.');
}

List<JsonMap> requireJsonList(Object? value, {String context = 'response'}) {
  if (value is! List) {
    throw FormatException('Expected a JSON array for $context.');
  }
  return value
      .map((item) => requireJsonMap(item, context: '$context item'))
      .toList(growable: false);
}

Object? unwrapData(Object? response) {
  final json = requireJsonMap(response);
  return json['data'];
}

class CursorPage<T> {
  const CursorPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  factory CursorPage.fromJson(
    Object? response,
    T Function(JsonMap json) fromJson,
  ) {
    final root = requireJsonMap(response);
    final data = requireJsonList(root['data'], context: 'page data');
    final page = requireJsonMap(root['page'], context: 'page metadata');
    return CursorPage(
      items: data.map(fromJson).toList(growable: false),
      nextCursor: page['nextCursor'] as String?,
      hasMore: page['hasMore'] as bool? ?? false,
    );
  }

  final List<T> items;
  final String? nextCursor;
  final bool hasMore;
}
