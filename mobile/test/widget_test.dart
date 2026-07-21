import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawket_mobile/app/pawket_app.dart';
import 'package:pawket_mobile/app/bootstrap/app_providers.dart';
import 'package:pawket_mobile/features/pets/data/pet_dto.dart';
import 'package:pawket_mobile/features/pets/data/pet_repository.dart';
import 'package:pawket_mobile/features/pets/domain/pet.dart';

void main() {
  testWidgets('opens on camera and reaches home', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          petRepositoryProvider.overrideWithValue(_FakePetRepository()),
        ],
        child: const PawketApp(),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Open photo library'), findsNothing);
    expect(find.bySemanticsLabel('Take photo'), findsOneWidget);
    expect(find.byTooltip('Flash off'), findsOneWidget);
    expect(find.byTooltip('Switch camera'), findsOneWidget);
    expect(find.byTooltip('Open home'), findsOneWidget);

    await tester.tap(find.byTooltip('Open home'));
    await tester.pumpAndSettle();

    expect(find.text('Today with Mit'), findsOneWidget);
    expect(find.text('Mit'), findsWidgets);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Mit'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a pet'), findsOneWidget);
    expect(find.text('All pets'), findsNothing);
    expect(find.text('Add another pet'), findsOneWidget);
  });
}

class _FakePetRepository implements PetRepository {
  final pet = Pet(
    id: 'mit',
    name: 'Mit',
    species: PetSpecies.dog,
    accent: const Color(0xFFC45132),
    homeSince: DateTime(2024, 2, 14),
  );

  @override
  Future<Pet> createPet(
    CreatePetRequest request, {
    required String idempotencyKey,
  }) async => pet;

  @override
  Future<PetDto> getPet(String petId) async => PetDto(
    id: pet.id,
    name: pet.name,
    species: PetSpeciesDto.dog,
    adoptionDate: pet.homeSince,
    permissions: const {'READ'},
  );

  @override
  Future<List<Pet>> listAccessiblePets() async => [pet];

  @override
  Future<PetDto> updatePet(String petId, UpdatePetRequest request) {
    return getPet(petId);
  }
}
