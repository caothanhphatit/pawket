import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawket_mobile/app/bootstrap/app_providers.dart';
import 'package:pawket_mobile/app/theme/pawket_theme.dart';
import 'package:pawket_mobile/features/pets/data/pet_dto.dart';
import 'package:pawket_mobile/features/pets/data/pet_repository.dart';
import 'package:pawket_mobile/features/pets/domain/pet.dart';
import 'package:pawket_mobile/features/pets/presentation/pet_bootstrap_gate.dart';

void main() {
  testWidgets('requires a first pet before revealing the app', (tester) async {
    final repository = _EmptyPetRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [petRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: PawketTheme.light(),
          home: const PetBootstrapGate(child: Text('CAMERA APP')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your first pet'), findsOneWidget);
    expect(find.text('CAMERA APP'), findsNothing);
    expect(find.text('Skip'), findsNothing);
    expect(find.byType(BackButton), findsNothing);

    await tester.enterText(find.byType(TextFormField), 'Mit');
    final createButton = find.widgetWithText(FilledButton, 'Create profile');
    await tester.drag(find.byType(ListView), const Offset(0, -320));
    await tester.pumpAndSettle();
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('CAMERA APP'), findsOneWidget);
    expect(repository.pets.single.name, 'Mit');
  });
}

class _EmptyPetRepository implements PetRepository {
  final pets = <Pet>[];

  @override
  Future<Pet> createPet(
    CreatePetRequest request, {
    required String idempotencyKey,
  }) async {
    final pet = Pet(
      id: 'mit',
      name: request.name,
      species: request.species == PetSpeciesDto.dog
          ? PetSpecies.dog
          : PetSpecies.cat,
      accent: const Color(0xFFC45132),
    );
    pets.add(pet);
    return pet;
  }

  @override
  Future<PetDto> getPet(String petId) async => throw UnimplementedError();

  @override
  Future<List<Pet>> listAccessiblePets() async => List.of(pets);

  @override
  Future<PetDto> updatePet(String petId, UpdatePetRequest request) async =>
      throw UnimplementedError();
}
