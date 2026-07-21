import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/pawket_theme.dart';
import '../../../app/widgets/pawket_scaffold.dart';
import '../../feed/application/feed_providers.dart';
import '../../pets/application/pet_providers.dart';
import '../../pets/presentation/widgets/pet_avatar.dart';
import '../../posts/data/post_dto.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = ref.watch(activePetProvider);
    final loadState = ref.watch(petLoadStateProvider);
    final memories = pet == null
        ? null
        : ref.watch(petMemoriesProvider(pet.id));

    return PawketScaffold(
      currentIndex: -1,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(petsProvider.notifier).refresh();
          final currentPet = ref.read(activePetProvider);
          if (currentPet != null) {
            ref.invalidate(petMemoriesProvider(currentPet.id));
          }
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today with ${pet?.name ?? 'your pet'}',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'One small moment becomes part of a lifetime.',
                      style: TextStyle(color: PawketColors.inkMuted),
                    ),
                    if (loadState.isOfflineFallback) ...[
                      const SizedBox(height: 12),
                      const _OfflineNotice(),
                    ],
                  ],
                ),
              ),
            ),
            if (pet != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: SizedBox(
                    height: 96,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 170,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: PawketColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: PawketColors.outline),
                        ),
                        child: Row(
                          children: [
                            PetAvatar(pet: pet),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pet.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    memories?.value?.items.isNotEmpty == true
                                        ? 'Remembered'
                                        : 'Ready today',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: PawketColors.leaf,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
              sliver: SliverToBoxAdapter(
                child: _HomeContent(
                  petName: pet?.name,
                  petLoading: loadState.isLoading,
                  petError: loadState.error,
                  memories: memories,
                  onRetry: () => ref.read(petsProvider.notifier).refresh(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.petName,
    required this.petLoading,
    required this.petError,
    required this.memories,
    required this.onRetry,
  });

  final String? petName;
  final bool petLoading;
  final Object? petError;
  final AsyncValue<dynamic>? memories;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (petName == null) {
      if (petLoading) return const Center(child: CircularProgressIndicator());
      return _MessageCard(
        icon: petError == null ? Icons.pets_outlined : Icons.cloud_off_outlined,
        title: petError == null
            ? 'Create your first pet'
            : 'Could not load pets',
        body: petError == null
            ? 'A lifetime profile starts with a name.'
            : 'Check that the Pawket API is running, then try again.',
        actionLabel: petError == null ? null : 'Try again',
        onAction: petError == null ? null : onRetry,
      );
    }

    return memories!.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _MessageCard(
        icon: Icons.cloud_off_outlined,
        title: 'Memories are taking a nap',
        body: 'Pull down or tap below to try again.',
        actionLabel: 'Try again',
        onAction: onRetry,
      ),
      data: (page) {
        final posts = page.items as List<PostDto>;
        if (posts.isEmpty) {
          return const _MessageCard(
            icon: Icons.add_a_photo_outlined,
            title: 'No memory yet',
            body: 'Open the camera and save today’s first moment.',
          );
        }
        final post = posts.first;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dateLabel(post.capturedAt),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: PawketColors.inkMuted,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            _MemoryCard(petName: petName!, post: post),
          ],
        );
      },
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.petName, required this.post});

  final String petName;
  final PostDto post;

  @override
  Widget build(BuildContext context) {
    final media = post.media.firstOrNull;
    return InkWell(
      onTap: () => context.push('/posts/${post.id}', extra: post),
      borderRadius: BorderRadius.circular(12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: media == null
                  ? const _MemoryPlaceholder()
                  : Image.network(
                      (media.thumbnailUrl ?? media.url).toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _MemoryPlaceholder(),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          petName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        tooltip: 'React with love',
                        icon: Icon(
                          post.reactions.currentUserReaction == null
                              ? Icons.favorite_border
                              : Icons.favorite,
                        ),
                      ),
                    ],
                  ),
                  if (post.caption?.trim().isNotEmpty == true) ...[
                    Text(post.caption!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    'by ${post.author.displayName}',
                    style: const TextStyle(color: PawketColors.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryPlaceholder extends StatelessWidget {
  const _MemoryPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF71867B), Color(0xFFD7B58C)],
        ),
      ),
      child: Center(child: Icon(Icons.pets, size: 76, color: Colors.white70)),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 36, color: PawketColors.inkMuted),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(color: PawketColors.inkMuted),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.cloud_off_outlined, size: 16, color: PawketColors.inkMuted),
        SizedBox(width: 6),
        Text(
          'Offline preview',
          style: TextStyle(color: PawketColors.inkMuted, fontSize: 12),
        ),
      ],
    );
  }
}

String _dateLabel(DateTime value) {
  const months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];
  final local = value.toLocal();
  return '${local.day} ${months[local.month - 1]}';
}
