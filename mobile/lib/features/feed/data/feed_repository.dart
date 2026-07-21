import '../../../core/network/api_client.dart';
import '../../../core/network/api_models.dart';
import '../../posts/data/post_dto.dart';

abstract interface class FeedRepository {
  Future<CursorPage<PostDto>> getFeed({
    required String petId,
    String? cursor,
    int limit = 20,
  });

  Future<CursorPage<PostDto>> getPetMemories({
    required String petId,
    String? cursor,
    int limit = 30,
  });
}

class RemoteFeedRepository implements FeedRepository {
  const RemoteFeedRepository(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<CursorPage<PostDto>> getFeed({
    required String petId,
    String? cursor,
    int limit = 20,
  }) async {
    final response = await _apiClient.get<Object>(
      '/feed',
      queryParameters: {'petId': petId, 'limit': limit, 'cursor': ?cursor},
    );
    return CursorPage.fromJson(
      response.data,
      (json) => PostDto.fromJson(json, baseUri: _apiClient.resolveUri(Uri())),
    );
  }

  @override
  Future<CursorPage<PostDto>> getPetMemories({
    required String petId,
    String? cursor,
    int limit = 30,
  }) async {
    final response = await _apiClient.get<Object>(
      '/pets/$petId/timeline',
      queryParameters: {'limit': limit, 'cursor': ?cursor},
    );
    return CursorPage.fromJson(
      response.data,
      (json) => PostDto.fromJson(json, baseUri: _apiClient.resolveUri(Uri())),
    );
  }
}
