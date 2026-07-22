import '../../../core/network/api_client.dart';
import '../../../core/network/api_models.dart';
import 'comment_dto.dart';

abstract interface class CommentRepository {
  Future<CursorPage<CommentDto>> list(String postId);
  Future<CommentDto> create(
    String postId,
    CreateCommentRequest request, {
    required String idempotencyKey,
  });
  Future<CommentDto> update(
    String commentId,
    UpdateCommentRequest request, {
    required String idempotencyKey,
  });
  Future<void> delete(String commentId);
}

class RemoteCommentRepository implements CommentRepository {
  const RemoteCommentRepository(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<CursorPage<CommentDto>> list(String postId) async {
    final response = await _apiClient.get<Object>(
      '/posts/$postId/comments',
      queryParameters: const {'limit': 100},
    );
    return _commentPage(response.data);
  }

  @override
  Future<CommentDto> create(
    String postId,
    CreateCommentRequest request, {
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.post<Object>(
      '/posts/$postId/comments',
      data: request.toJson(),
      idempotencyKey: idempotencyKey,
    );
    return CommentDto.fromJson(
      requireJsonMap(unwrapData(response.data), context: 'created comment'),
    );
  }

  @override
  Future<CommentDto> update(
    String commentId,
    UpdateCommentRequest request, {
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.patch<Object>(
      '/comments/$commentId',
      data: request.toJson(),
      idempotencyKey: idempotencyKey,
    );
    return CommentDto.fromJson(
      requireJsonMap(unwrapData(response.data), context: 'updated comment'),
    );
  }

  @override
  Future<void> delete(String commentId) async {
    await _apiClient.delete<void>('/comments/$commentId');
  }
}

CursorPage<CommentDto> _commentPage(Object? response) {
  final root = requireJsonMap(response);
  final data = requireJsonList(root['data'], context: 'comments');
  final page = root['page'] is Map
      ? requireJsonMap(root['page'], context: 'comment page')
      : const <String, dynamic>{};
  return CursorPage(
    items: data.map(CommentDto.fromJson).toList(growable: false),
    nextCursor: page['nextCursor'] as String?,
    hasMore: page['hasMore'] as bool? ?? false,
  );
}
