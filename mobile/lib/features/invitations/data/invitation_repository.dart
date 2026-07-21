import '../../../core/network/api_client.dart';
import '../../../core/network/api_models.dart';
import 'invitation_dto.dart';

abstract interface class InvitationRepository {
  Future<InvitationDto> createInvitation(
    String petId,
    CreateInvitationRequest request, {
    required String idempotencyKey,
  });

  Future<InvitationDto> previewInvitation(String token);
  Future<InvitationDto> acceptInvitation(
    String token, {
    required String idempotencyKey,
  });
}

class RemoteInvitationRepository implements InvitationRepository {
  const RemoteInvitationRepository(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<InvitationDto> createInvitation(
    String petId,
    CreateInvitationRequest request, {
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.post<Object>(
      '/invitations',
      data: {'petId': petId, ...request.toJson()},
      idempotencyKey: idempotencyKey,
    );
    return _invitation(
      response.data,
      'created invitation',
      fallbackPetId: petId,
      fallbackRole: request.requestedRole,
    );
  }

  @override
  Future<InvitationDto> previewInvitation(String token) async {
    final response = await _apiClient.get<Object>('/invitations/$token');
    return _invitation(response.data, 'invitation preview');
  }

  @override
  Future<InvitationDto> acceptInvitation(
    String token, {
    required String idempotencyKey,
  }) async {
    final invitation = await previewInvitation(token);
    await _apiClient.post<Object>(
      '/invitations/accept',
      data: {'token': token},
      idempotencyKey: idempotencyKey,
    );
    return invitation;
  }

  InvitationDto _invitation(
    Object? response,
    String context, {
    String? fallbackPetId,
    PetMemberRole? fallbackRole,
  }) {
    return InvitationDto.fromJson(
      requireJsonMap(unwrapData(response), context: context),
      fallbackPetId: fallbackPetId,
      fallbackRole: fallbackRole,
    );
  }
}
