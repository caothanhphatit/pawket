import 'package:flutter/material.dart';
import 'package:pawket_mobile/features/pets/domain/pet.dart';

class PetAvatar extends StatelessWidget {
  const PetAvatar({
    required this.pet,
    this.radius = 22,
    this.selected = false,
    super.key,
  });

  final Pet pet;
  final double radius;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${pet.name}, ${pet.speciesLabel}${selected ? ', selected' : ''}',
      child: CircleAvatar(
        radius: radius,
        backgroundColor: pet.accent,
        foregroundColor: Colors.white,
        child: pet.avatarUrl == null
            ? Text(
                pet.initial,
                style: TextStyle(
                  fontSize: radius * .85,
                  fontWeight: FontWeight.w700,
                ),
              )
            : ClipOval(
                child: Image.network(
                  pet.avatarUrl.toString(),
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Center(
                    child: Text(
                      pet.initial,
                      style: TextStyle(
                        fontSize: radius * .85,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
