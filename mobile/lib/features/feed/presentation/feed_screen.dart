import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/pawket_theme.dart';
import '../../../app/widgets/pawket_scaffold.dart';
import '../../pets/application/pet_providers.dart';
import '../../posts/data/post_dto.dart';
import '../../reactions/application/reaction_providers.dart';
import '../../reactions/presentation/reaction_control.dart';
import '../application/feed_providers.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = ref.watch(activePetProvider);
    final loadState = ref.watch(petLoadStateProvider);
    final feed = pet == null ? null : ref.watch(petFeedProvider(pet.id));

    return PawketScaffold(
      currentIndex: 0,
      body: RefreshIndicator(
        onRefresh: () async {
          if (pet != null) ref.invalidate(petFeedProvider(pet.id));
          await ref.read(petsProvider.notifier).refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Feed',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pet?.name ?? 'Pet'}\'s latest moments',
                      style: const TextStyle(color: PawketColors.inkMuted),
                    ),
                  ],
                ),
              ),
            ),
            if (pet == null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _FeedMessage(
                  loading: loadState.isLoading,
                  hasError: loadState.error != null,
                  onRetry: () => ref.read(petsProvider.notifier).refresh(),
                ),
              )
            else
              feed!.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: _FeedMessage(
                    hasError: true,
                    onRetry: () => ref.invalidate(petFeedProvider(pet.id)),
                  ),
                ),
                data: (page) => page.items.isEmpty
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _FeedMessage(),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        sliver: SliverList.separated(
                          itemCount: page.items.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) => _FeedCard(
                            petName: pet.name,
                            post: page.items[index],
                            index: index,
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    this.loading = false,
    this.hasError = false,
    this.onRetry,
  });

  final bool loading;
  final bool hasError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasError
                  ? Icons.cloud_off_outlined
                  : Icons.photo_library_outlined,
              size: 40,
              color: PawketColors.inkMuted,
            ),
            const SizedBox(height: 12),
            Text(
              hasError ? 'Could not load the feed' : 'The feed is quiet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              hasError
                  ? 'Check the connection and try again.'
                  : 'New memories will appear here.',
              style: const TextStyle(color: PawketColors.inkMuted),
            ),
            if (hasError) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedCard extends ConsumerWidget {
  const _FeedCard({
    required this.petName,
    required this.post,
    required this.index,
  });

  final String petName;
  final PostDto post;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const colors = [
      [Color(0xFF71867B), Color(0xFFD7B58C)],
      [Color(0xFF405D52), Color(0xFF8DA18F)],
      [Color(0xFFB46A4D), Color(0xFFE0B890)],
    ];
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
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colors[index % colors.length],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.pets,
                          size: 68,
                          color: Colors.white60,
                        ),
                      ),
                    )
                  : Image.network(
                      (media.thumbnailUrl ?? media.url).toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: colors[index % colors.length].first,
                        child: const Center(
                          child: Icon(
                            Icons.pets,
                            size: 68,
                            color: Colors.white60,
                          ),
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    petName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  if (post.caption?.trim().isNotEmpty == true) ...[
                    Text(
                      post.caption!,
                      style: const TextStyle(color: PawketColors.inkMuted),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    _relativeDate(post.capturedAt),
                    style: const TextStyle(
                      color: PawketColors.inkMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ReactionControl(
                    summary: post.reactions,
                    onChanged: (reaction) {
                      final repository = ref.read(reactionRepositoryProvider);
                      if (reaction == null) {
                        return repository.removeReaction(post.id);
                      }
                      return repository.setReaction(
                        postId: post.id,
                        type: reaction,
                        idempotencyKey: const Uuid().v4(),
                      );
                    },
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

String _relativeDate(DateTime value) {
  final difference = DateTime.now().difference(value.toLocal());
  if (difference.inDays == 0) return 'Today';
  if (difference.inDays == 1) return 'Yesterday';
  return '${difference.inDays} days ago';
}
