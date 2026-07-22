import '../../../core/network/api_client.dart';
import '../../../core/network/api_models.dart';
import 'post_dto.dart';

abstract interface class PostRepository {
  Future<PostDto> getPost(String postId);
  Future<PostDto> createPost(
    CreatePostRequest request, {
    required String idempotencyKey,
  });
  Future<PostDto> updatePost(
    String postId,
    UpdatePostRequest request, {
    required String idempotencyKey,
  });
  Future<void> deletePost(String postId);
}

class RemotePostRepository implements PostRepository {
  const RemotePostRepository(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<PostDto> getPost(String postId) async {
    final response = await _apiClient.get<Object>('/posts/$postId');
    return PostDto.fromJson(
      requireJsonMap(unwrapData(response.data), context: 'post'),
      baseUri: _apiClient.resolveUri(Uri()),
    );
  }

  @override
  Future<PostDto> createPost(
    CreatePostRequest request, {
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.post<Object>(
      '/posts',
      data: request.toJson(),
      idempotencyKey: idempotencyKey,
    );
    return PostDto.fromJson(
      requireJsonMap(unwrapData(response.data), context: 'created post'),
      baseUri: _apiClient.resolveUri(Uri()),
    );
  }

  @override
  Future<PostDto> updatePost(
    String postId,
    UpdatePostRequest request, {
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.patch<Object>(
      '/posts/$postId',
      data: request.toJson(),
      idempotencyKey: idempotencyKey,
    );
    return PostDto.fromJson(
      requireJsonMap(unwrapData(response.data), context: 'updated post'),
      baseUri: _apiClient.resolveUri(Uri()),
    );
  }

  @override
  Future<void> deletePost(String postId) async {
    await _apiClient.delete<void>('/posts/$postId');
  }
}
