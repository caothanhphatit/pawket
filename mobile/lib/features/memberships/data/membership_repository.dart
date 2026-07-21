import '../../../core/network/api_client.dart';
import '../../../core/network/api_models.dart';
import 'member_dto.dart';

abstract interface class MembershipRepository {
  Future<List<MemberDto>> listMembers(String petId);
  Future<void> removeMember(String petId, String userId);
}

class RemoteMembershipRepository implements MembershipRepository {
  const RemoteMembershipRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<MemberDto>> listMembers(String petId) async {
    final response = await _apiClient.get<Object>('/pets/$petId/members');
    return requireJsonList(
      unwrapData(response.data),
      context: 'pet members',
    ).map(MemberDto.fromJson).toList(growable: false);
  }

  @override
  Future<void> removeMember(String petId, String userId) async {
    await _apiClient.delete<void>('/pets/$petId/members/$userId');
  }
}
