import '../../../core/network/api_client.dart';
import '../../../core/network/api_models.dart';
import '../../posts/data/post_dto.dart';
import 'reaction_person_dto.dart';

abstract interface class ReactionRepository {
  Future<ReactionSummaryDto> setReaction({
    required String postId,
    required String type,
    required String idempotencyKey,
  });

  Future<ReactionSummaryDto> removeReaction(String postId);
  Future<List<ReactionPersonDto>> listPeople(String postId);
}

class RemoteReactionRepository implements ReactionRepository {
  const RemoteReactionRepository(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<ReactionSummaryDto> setReaction({
    required String postId,
    required String type,
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.put<Object>(
      '/posts/$postId/reaction',
      data: {'type': type},
      idempotencyKey: idempotencyKey,
    );
    return ReactionSummaryDto.fromJson(
      requireJsonMap(unwrapData(response.data), context: 'reaction summary'),
    );
  }

  @override
  Future<ReactionSummaryDto> removeReaction(String postId) async {
    final response = await _apiClient.delete<Object>('/posts/$postId/reaction');
    return ReactionSummaryDto.fromJson(
      requireJsonMap(unwrapData(response.data), context: 'reaction summary'),
    );
  }

  @override
  Future<List<ReactionPersonDto>> listPeople(String postId) async {
    final response = await _apiClient.get<Object>(
      '/posts/$postId/reaction/people',
    );
    return requireJsonList(
      unwrapData(response.data),
      context: 'reaction people',
    ).map(ReactionPersonDto.fromJson).toList(growable: false);
  }
}
