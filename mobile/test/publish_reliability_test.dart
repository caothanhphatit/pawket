import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pawket_mobile/app/bootstrap/app_providers.dart';
import 'package:pawket_mobile/core/network/api_exception.dart';
import 'package:pawket_mobile/features/pets/application/pet_providers.dart';
import 'package:pawket_mobile/features/pets/data/pet_dto.dart';
import 'package:pawket_mobile/features/pets/data/pet_repository.dart';
import 'package:pawket_mobile/features/pets/domain/pet.dart';
import 'package:pawket_mobile/features/posts/data/post_dto.dart';
import 'package:pawket_mobile/features/posts/presentation/capture_draft.dart';

void main() {
  test('capture draft preserves the shutter timestamp', () async {
    final capturedAt = DateTime.utc(2026, 7, 21, 8, 30);
    final draft = CaptureDraft(
      media: XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'memory.jpg'),
      capturedAt: capturedAt,
    );

    expect(draft.capturedAt, capturedAt);
    expect(await draft.media.readAsBytes(), Uint8List.fromList([1, 2, 3]));
  });

  test('blank captions are omitted from create post requests', () {
    final request = CreatePostRequest(
      petIds: const ['pet-id'],
      mediaIds: const ['media-id'],
      capturedAt: DateTime.utc(2026, 7, 21),
      caption: '   ',
    );

    expect(request.toJson(), isNot(contains('caption')));
  });

  test('offline pet creation fails without adding a fake pet', () async {
    final container = ProviderContainer(
      overrides: [
        petRepositoryProvider.overrideWithValue(_OfflinePetRepository()),
      ],
    );
    addTearDown(container.dispose);
    final notifier = container.read(petsProvider.notifier);

    await expectLater(
      notifier.add(name: 'Mit', species: PetSpecies.dog),
      throwsA(isA<NetworkException>()),
    );
    expect(container.read(petsProvider), isEmpty);
  });
}

class _OfflinePetRepository implements PetRepository {
  @override
  Future<Pet> createPet(
    CreatePetRequest request, {
    required String idempotencyKey,
  }) async => throw const NetworkException('offline');

  @override
  Future<PetDto> getPet(String petId) async =>
      throw const NetworkException('offline');

  @override
  Future<List<Pet>> listAccessiblePets() async => const [];

  @override
  Future<PetDto> updatePet(String petId, UpdatePetRequest request) async =>
      throw const NetworkException('offline');
}
