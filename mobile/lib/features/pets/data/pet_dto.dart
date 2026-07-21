import 'package:flutter/material.dart';

import '../../../core/network/api_models.dart';
import '../domain/pet.dart';

class PetDto {
  const PetDto({
    required this.id,
    required this.name,
    required this.species,
    required this.permissions,
    this.avatarUrl,
    this.birthDate,
    this.estimatedBirth = false,
    this.gender,
    this.breed,
    this.adoptionDate,
    this.bio,
    this.version,
  });

  factory PetDto.fromJson(JsonMap json, {Uri? baseUri}) {
    final avatarValue = json['avatarUrl'] as String?;
    final avatarMediaId = json['avatarMediaId'] as String?;
    return PetDto(
      id: json['id'] as String,
      name: json['name'] as String,
      species: PetSpeciesDto.fromWire(json['species'] as String),
      avatarUrl: _resolvedAvatarUrl(
        avatarValue ??
            (avatarMediaId == null
                ? null
                : '/api/v1/media/$avatarMediaId/content'),
        baseUri,
      ),
      birthDate: _optionalDate(json['birthDate']),
      estimatedBirth: json['estimatedBirth'] as bool? ?? false,
      gender: json['gender'] as String?,
      breed: json['breed'] as String?,
      adoptionDate: _optionalDate(json['adoptionDate']),
      bio: json['bio'] as String?,
      permissions: (json['permissions'] as List? ?? const ['READ'])
          .whereType<String>()
          .toSet(),
      version: (json['version'] as num?)?.toInt(),
    );
  }

  final String id;
  final String name;
  final PetSpeciesDto species;
  final String? avatarUrl;
  final DateTime? birthDate;
  final bool estimatedBirth;
  final String? gender;
  final String? breed;
  final DateTime? adoptionDate;
  final String? bio;
  final Set<String> permissions;
  final int? version;

  Pet toDomain() {
    return Pet(
      id: id,
      name: name,
      species: species == PetSpeciesDto.dog ? PetSpecies.dog : PetSpecies.cat,
      accent: _accentFor(id),
      avatarUrl: avatarUrl == null ? null : Uri.parse(avatarUrl!),
      homeSince: adoptionDate,
    );
  }

  static Color _accentFor(String id) {
    const accents = [
      Color(0xFFCC5033),
      Color(0xFF708A7C),
      Color(0xFFD7AE7D),
      Color(0xFF527386),
    ];
    return accents[id.hashCode.abs() % accents.length];
  }
}

enum PetSpeciesDto {
  dog('DOG'),
  cat('CAT');

  const PetSpeciesDto(this.wireValue);
  final String wireValue;

  static PetSpeciesDto fromWire(String value) {
    return PetSpeciesDto.values.firstWhere(
      (species) => species.wireValue == value,
      orElse: () => throw FormatException('Unknown pet species: $value'),
    );
  }
}

class CreatePetRequest {
  const CreatePetRequest({
    required this.name,
    required this.species,
    this.birthDate,
    this.estimatedBirth = false,
    this.gender,
    this.breed,
    this.adoptionDate,
    this.bio,
  });

  final String name;
  final PetSpeciesDto species;
  final DateTime? birthDate;
  final bool estimatedBirth;
  final String? gender;
  final String? breed;
  final DateTime? adoptionDate;
  final String? bio;

  JsonMap toJson() => {
    'name': name.trim(),
    'species': species.wireValue,
    if (birthDate != null) 'birthDate': _dateOnly(birthDate!),
    'estimatedBirth': estimatedBirth,
    if (gender != null) 'gender': gender,
    if (breed != null) 'breed': breed!.trim(),
    if (adoptionDate != null) 'adoptionDate': _dateOnly(adoptionDate!),
    if (bio != null) 'bio': bio!.trim(),
  };
}

class UpdatePetRequest {
  const UpdatePetRequest({
    this.name,
    this.avatarMediaId,
    this.birthDate,
    this.estimatedBirth,
    this.gender,
    this.breed,
    this.adoptionDate,
    this.bio,
    this.version,
  });

  final String? name;
  final String? avatarMediaId;
  final DateTime? birthDate;
  final bool? estimatedBirth;
  final String? gender;
  final String? breed;
  final DateTime? adoptionDate;
  final String? bio;
  final int? version;

  JsonMap toJson() => {
    if (name != null) 'name': name!.trim(),
    if (avatarMediaId != null) 'avatarMediaId': avatarMediaId,
    if (birthDate != null) 'birthDate': _dateOnly(birthDate!),
    if (estimatedBirth != null) 'estimatedBirth': estimatedBirth,
    if (gender != null) 'gender': gender,
    if (breed != null) 'breed': breed!.trim(),
    if (adoptionDate != null) 'adoptionDate': _dateOnly(adoptionDate!),
    if (bio != null) 'bio': bio!.trim(),
    if (version != null) 'version': version,
  };
}

Uri _resolveUri(String value, Uri? baseUri) {
  final uri = Uri.parse(value);
  return uri.hasScheme || baseUri == null ? uri : baseUri.resolveUri(uri);
}

String? _resolvedAvatarUrl(String? value, Uri? baseUri) {
  return value == null ? null : _resolveUri(value, baseUri).toString();
}

DateTime? _optionalDate(Object? value) {
  return value is String ? DateTime.tryParse(value) : null;
}

String _dateOnly(DateTime value) {
  final date = value.toLocal();
  String twoDigits(int part) => part.toString().padLeft(2, '0');
  return '${date.year}-${twoDigits(date.month)}-${twoDigits(date.day)}';
}
