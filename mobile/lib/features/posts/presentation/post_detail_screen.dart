import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/bootstrap/app_providers.dart';
import '../../../app/theme/pawket_theme.dart';
import '../../reactions/application/reaction_providers.dart';
import '../../reactions/presentation/reaction_control.dart';
import '../data/post_dto.dart';

final postDetailProvider = FutureProvider.autoDispose.family<PostDto, String>(
  (ref, postId) => ref.watch(postRepositoryProvider).getPost(postId),
);

class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({required this.postId, this.initialPost, super.key});

  final String postId;
  final PostDto? initialPost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = initialPost;
    return Scaffold(
      appBar: AppBar(title: const Text('Memory')),
      body: initial != null
          ? _PostDetailContent(post: initial)
          : ref
                .watch(postDetailProvider(postId))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: FilledButton.tonal(
                      onPressed: () =>
                          ref.invalidate(postDetailProvider(postId)),
                      child: const Text('Try again'),
                    ),
                  ),
                  data: (post) => _PostDetailContent(post: post),
                ),
    );
  }
}

class _PostDetailContent extends ConsumerWidget {
  const _PostDetailContent({required this.post});

  final PostDto post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = post.media.firstOrNull;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: media == null
              ? const ColoredBox(
                  color: PawketColors.surfaceStrong,
                  child: Icon(Icons.pets, size: 72),
                )
              : InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.network(
                    (media.thumbnailUrl ?? media.url).toString(),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const ColoredBox(
                      color: PawketColors.surfaceStrong,
                      child: Icon(Icons.broken_image_outlined, size: 56),
                    ),
                  ),
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dateLabel(post.capturedAt),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
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
              if (post.caption?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 12),
                Text(post.caption!, style: const TextStyle(fontSize: 17)),
              ],
              const SizedBox(height: 12),
              Text(
                'by ${post.author.displayName}',
                style: const TextStyle(color: PawketColors.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _dateLabel(DateTime value) {
  final local = value.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}
