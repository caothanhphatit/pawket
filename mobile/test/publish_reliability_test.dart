import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as image;
import 'package:pawket_mobile/app/bootstrap/app_providers.dart';
import 'package:pawket_mobile/core/network/api_exception.dart';
import 'package:pawket_mobile/features/pets/application/pet_providers.dart';
import 'package:pawket_mobile/features/pets/data/pet_dto.dart';
import 'package:pawket_mobile/features/pets/data/pet_repository.dart';
import 'package:pawket_mobile/features/pets/domain/pet.dart';
import 'package:pawket_mobile/features/posts/data/post_dto.dart';
import 'package:pawket_mobile/features/posts/domain/photo_filter.dart';
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

  test('post updates can clear caption and change audience', () {
    const request = UpdatePostRequest(
      caption: '   ',
      visibility: 'PRIVATE',
      version: 3,
    );

    expect(request.toJson(), {
      'caption': null,
      'visibility': 'PRIVATE',
      'version': 3,
    });
  });

  test('default photo polish bakes EXIF orientation before encoding', () async {
    final source = image.Image(width: 2, height: 3)
      ..exif.imageIfd.orientation = 6;
    final filtered = await PawketPhotoFilter.applyToBytes(
      image.encodeJpg(source),
    );
    final decoded = image.decodeJpg(filtered!);

    expect(decoded?.width, 3);
    expect(decoded?.height, 2);
    expect(decoded?.exif.imageIfd.orientation, isNot(6));
  });

  test('upload preparation bounds the longest image dimension', () async {
    final source = image.Image(width: 2400, height: 600);
    final prepared = await PawketPhotoFilter.prepareForUpload(
      image.encodeJpg(source),
    );

    expect(prepared.width, PawketPhotoFilter.maxOutputDimension);
    expect(prepared.height, 512);
    expect(prepared.bytes, isNotEmpty);
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
