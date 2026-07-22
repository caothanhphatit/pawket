import '../../../core/network/api_client.dart';
import '../../../core/network/api_models.dart';
import 'milestone_dto.dart';

abstract interface class MilestoneRepository {
  Future<List<MilestoneDto>> listMilestones(String petId);
  Future<MilestoneDto> createMilestone(
    String petId,
    CreateMilestoneRequest request,
  );
  Future<void> deleteMilestone(String petId, String milestoneId);
}

class RemoteMilestoneRepository implements MilestoneRepository {
  const RemoteMilestoneRepository(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<List<MilestoneDto>> listMilestones(String petId) async {
    final response = await _apiClient.get<Object>('/pets/$petId/milestones');
    return requireJsonList(
      unwrapData(response.data),
      context: 'pet milestones',
    ).map(MilestoneDto.fromJson).toList(growable: false);
  }

  @override
  Future<MilestoneDto> createMilestone(
    String petId,
    CreateMilestoneRequest request,
  ) async {
    final response = await _apiClient.post<Object>(
      '/pets/$petId/milestones',
      data: request.toJson(),
    );
    return MilestoneDto.fromJson(
      requireJsonMap(unwrapData(response.data), context: 'created milestone'),
    );
  }

  @override
  Future<void> deleteMilestone(String petId, String milestoneId) async {
    await _apiClient.delete<void>('/pets/$petId/milestones/$milestoneId');
  }
}
