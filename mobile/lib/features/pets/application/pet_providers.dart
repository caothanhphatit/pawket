import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../app/bootstrap/app_providers.dart';
import '../data/pet_dto.dart';
import '../domain/pet.dart';

enum PetDataOrigin { remote, localFallback }

@immutable
class PetLoadState {
  const PetLoadState({
    this.isLoading = false,
    this.origin = PetDataOrigin.remote,
    this.error,
  });

  final bool isLoading;
  final PetDataOrigin origin;
  final Object? error;

  bool get isOfflineFallback => origin == PetDataOrigin.localFallback;
}

final petLoadStateProvider =
    NotifierProvider<PetLoadStateNotifier, PetLoadState>(
      PetLoadStateNotifier.new,
    );

class PetLoadStateNotifier extends Notifier<PetLoadState> {
  @override
  PetLoadState build() => const PetLoadState();

  void set(PetLoadState value) => state = value;
}

final petsProvider = NotifierProvider<PetsNotifier, List<Pet>>(
  PetsNotifier.new,
);

class PetsNotifier extends Notifier<List<Pet>> {
  bool _requestInFlight = false;

  @override
  List<Pet> build() {
    scheduleMicrotask(refresh);
    return const [];
  }

  Future<void> refresh() async {
    if (_requestInFlight) return;
    _requestInFlight = true;
    ref
        .read(petLoadStateProvider.notifier)
        .set(const PetLoadState(isLoading: true));
    try {
      state = await ref.read(petRepositoryProvider).listAccessiblePets();
      ref
          .read(petLoadStateProvider.notifier)
          .set(const PetLoadState(origin: PetDataOrigin.remote));
    } catch (error) {
      ref.read(petLoadStateProvider.notifier).set(PetLoadState(error: error));
    } finally {
      _requestInFlight = false;
    }
  }

  Future<Pet> add({required String name, required PetSpecies species}) async {
    final request = CreatePetRequest(
      name: name,
      species: species == PetSpecies.dog
          ? PetSpeciesDto.dog
          : PetSpeciesDto.cat,
    );

    final pet = await ref
        .read(petRepositoryProvider)
        .createPet(request, idempotencyKey: const Uuid().v4());
    state = [...state, pet];
    ref
        .read(petLoadStateProvider.notifier)
        .set(const PetLoadState(origin: PetDataOrigin.remote));
    return pet;
  }

  void replace(Pet pet) {
    state = [
      for (final candidate in state)
        if (candidate.id == pet.id) pet else candidate,
    ];
  }
}

const _activePetPreferenceKey = 'active_pet_id';

final activePetIdProvider = NotifierProvider<ActivePetNotifier, String?>(
  ActivePetNotifier.new,
);

class ActivePetNotifier extends Notifier<String?> {
  String? _selectedId;
  bool _restoreStarted = false;

  @override
  String? build() {
    final pets = ref.watch(petsProvider);
    if (!_restoreStarted) {
      _restoreStarted = true;
      unawaited(_restore());
    }

    if (pets.isEmpty) return null;
    if (pets.any((pet) => pet.id == _selectedId)) return _selectedId;
    _selectedId = pets.first.id;
    return _selectedId;
  }

  Future<void> _restore() async {
    final preferences = await SharedPreferences.getInstance();
    final savedId = preferences.getString(_activePetPreferenceKey);
    if (savedId == null) return;
    _selectedId = savedId;
    final pets = ref.read(petsProvider);
    if (pets.any((pet) => pet.id == savedId)) state = savedId;
  }

  void select(String petId) {
    _selectedId = petId;
    state = petId;
    unawaited(
      SharedPreferences.getInstance().then(
        (preferences) => preferences.setString(_activePetPreferenceKey, petId),
      ),
    );
  }
}

final activePetProvider = Provider<Pet?>((ref) {
  final activeId = ref.watch(activePetIdProvider);
  if (activeId == null) return null;

  for (final pet in ref.watch(petsProvider)) {
    if (pet.id == activeId) return pet;
  }
  return null;
});

final petDetailsProvider = FutureProvider.autoDispose.family<PetDto?, String>((
  ref,
  petId,
) async {
  return ref.watch(petRepositoryProvider).getPet(petId);
});
