import 'package:flutter/material.dart';

enum PetSpecies { dog, cat }

@immutable
class Pet {
  const Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.accent,
    this.avatarUrl,
    this.homeSince,
  });

  final String id;
  final String name;
  final PetSpecies species;
  final Color accent;
  final Uri? avatarUrl;
  final DateTime? homeSince;

  String get initial => name.characters.first.toUpperCase();

  String get speciesLabel => switch (species) {
    PetSpecies.dog => 'Dog',
    PetSpecies.cat => 'Cat',
  };
}
