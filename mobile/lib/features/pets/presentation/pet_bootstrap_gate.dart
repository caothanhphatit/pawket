import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/pawket_theme.dart';
import '../application/pet_providers.dart';
import 'create_pet_screen.dart';

class PetBootstrapGate extends ConsumerWidget {
  const PetBootstrapGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pets = ref.watch(petsProvider);
    final loadState = ref.watch(petLoadStateProvider);
    final completingOnboarding = ref.watch(petOnboardingCompletionProvider);

    if (pets.isEmpty && (!loadState.hasLoaded || loadState.isLoading)) {
      return const _PetBootstrapLoading();
    }
    if (pets.isEmpty && loadState.error != null) {
      return _PetBootstrapError(
        onRetry: () => ref.read(petsProvider.notifier).refresh(),
      );
    }
    if (pets.isEmpty || completingOnboarding) {
      return const CreatePetScreen(mandatory: true);
    }
    return child;
  }
}

class _PetBootstrapLoading extends StatelessWidget {
  const _PetBootstrapLoading();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: PawketColors.canvas,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets, size: 52, color: PawketColors.brand),
            SizedBox(height: 14),
            Text(
              'Pawket',
              style: TextStyle(
                color: PawketColors.ink,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 24),
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetBootstrapError extends StatelessWidget {
  const _PetBootstrapError({required this.onRetry});

  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PawketColors.canvas,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    size: 52,
                    color: PawketColors.inkMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pawket could not load your pets',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check your connection and try again. A pet profile is required before using the camera.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: PawketColors.inkMuted),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
