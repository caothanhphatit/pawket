import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pawket_mobile/app/theme/pawket_theme.dart';
import 'package:pawket_mobile/features/pets/application/pet_providers.dart';
import 'package:pawket_mobile/features/pets/presentation/widgets/pet_avatar.dart';

class PetContextHeader extends ConsumerWidget {
  const PetContextHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePet = ref.watch(activePetProvider);

    return Row(
      children: [
        Expanded(
          child: TextButton.icon(
            onPressed: () => _showPetSwitcher(context, ref),
            style: TextButton.styleFrom(
              foregroundColor: PawketColors.ink,
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.zero,
            ),
            icon: activePet == null
                ? const Icon(Icons.pets_outlined)
                : PetAvatar(pet: activePet, radius: 18, selected: true),
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    activePet?.name ?? 'Choose a pet',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.expand_more),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: () => context.go('/you'),
          tooltip: 'Open your profile',
          icon: const CircleAvatar(
            backgroundColor: PawketColors.surfaceStrong,
            foregroundColor: PawketColors.ink,
            child: Text('A'),
          ),
        ),
      ],
    );
  }

  Future<void> _showPetSwitcher(BuildContext context, WidgetRef ref) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: PawketColors.surface,
      builder: (context) {
        final pets = ref.read(petsProvider);
        final activeId = ref.read(activePetIdProvider);
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .72,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                Text(
                  'Choose a pet',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                for (final pet in pets)
                  ListTile(
                    leading: PetAvatar(pet: pet),
                    title: Text(pet.name),
                    subtitle: Text(pet.speciesLabel),
                    trailing: activeId == pet.id
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      ref.read(activePetIdProvider.notifier).select(pet.id);
                      Navigator.pop(context);
                    },
                  ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.add)),
                  title: const Text('Add another pet'),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/pets/new');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
