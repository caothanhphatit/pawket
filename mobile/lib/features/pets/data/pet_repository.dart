import '../../../core/network/api_client.dart';
import '../../../core/network/api_models.dart';
import '../domain/pet.dart';
import 'pet_dto.dart';

abstract interface class PetRepository {
  Future<List<Pet>> listAccessiblePets();
  Future<PetDto> getPet(String petId);
  Future<Pet> createPet(
    CreatePetRequest request, {
    required String idempotencyKey,
  });
  Future<PetDto> updatePet(String petId, UpdatePetRequest request);
}

class RemotePetRepository implements PetRepository {
  const RemotePetRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<Pet>> listAccessiblePets() async {
    final response = await _apiClient.get<Object>('/pets');
    final rows = requireJsonList(unwrapData(response.data), context: 'pets');
    return rows
        .map(
          (json) =>
              PetDto.fromJson(json, baseUri: _apiClient.resolveUri(Uri())),
        )
        .map((dto) => dto.toDomain())
        .toList();
  }

  @override
  Future<PetDto> getPet(String petId) async {
    final response = await _apiClient.get<Object>('/pets/$petId');
    return PetDto.fromJson(
      requireJsonMap(unwrapData(response.data), context: 'pet'),
      baseUri: _apiClient.resolveUri(Uri()),
    );
  }

  @override
  Future<Pet> createPet(
    CreatePetRequest request, {
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.post<Object>(
      '/pets',
      data: request.toJson(),
      idempotencyKey: idempotencyKey,
    );
    return PetDto.fromJson(
      requireJsonMap(unwrapData(response.data), context: 'created pet'),
      baseUri: _apiClient.resolveUri(Uri()),
    ).toDomain();
  }

  @override
  Future<PetDto> updatePet(String petId, UpdatePetRequest request) async {
    final response = await _apiClient.patch<Object>(
      '/pets/$petId',
      data: request.toJson(),
    );
    return PetDto.fromJson(
      requireJsonMap(unwrapData(response.data), context: 'updated pet'),
      baseUri: _apiClient.resolveUri(Uri()),
    );
  }
}
