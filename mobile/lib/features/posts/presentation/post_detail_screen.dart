import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/bootstrap/app_providers.dart';
import '../../../app/theme/pawket_theme.dart';
import '../../feed/application/feed_providers.dart';
import '../../reactions/application/reaction_providers.dart';
import '../../reactions/presentation/reaction_control.dart';
import '../data/post_dto.dart';

final postDetailProvider = FutureProvider.autoDispose.family<PostDto, String>(
  (ref, postId) => ref.watch(postRepositoryProvider).getPost(postId),
);

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({required this.postId, this.initialPost, super.key});

  final String postId;
  final PostDto? initialPost;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  PostDto? _post;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _post = widget.initialPost;
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    if (post == null) {
      ref.listen(postDetailProvider(widget.postId), (_, next) {
        next.whenData((value) {
          if (mounted) setState(() => _post = value);
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory'),
        actions: [
          if (_deleting)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (post != null) ...[
            IconButton(
              onPressed: () => _edit(post),
              tooltip: 'Edit memory',
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              onPressed: () => _delete(post),
              tooltip: 'Delete memory',
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
      body: post != null
          ? _PostDetailContent(post: post)
          : ref
                .watch(postDetailProvider(widget.postId))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: FilledButton.tonal(
                      onPressed: () =>
                          ref.invalidate(postDetailProvider(widget.postId)),
                      child: const Text('Try again'),
                    ),
                  ),
                  data: (post) => _PostDetailContent(post: post),
                ),
    );
  }

  Future<void> _edit(PostDto post) async {
    final updated = await showModalBottomSheet<PostDto>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EditMemorySheet(post: post),
    );
    if (updated == null || !mounted) return;
    setState(() => _post = updated);
    _refreshPostLists(ref, updated.petIds);
    ref.invalidate(postDetailProvider(updated.id));
  }

  Future<void> _delete(PostDto post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this memory?'),
        content: const Text(
          'This removes the memory from the pet profile and feed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: PawketColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(postRepositoryProvider).deletePost(post.id);
      _refreshPostLists(ref, post.petIds);
      ref.invalidate(postDetailProvider(post.id));
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete this memory. Try again.'),
        ),
      );
    }
  }
}

class _EditMemorySheet extends ConsumerStatefulWidget {
  const _EditMemorySheet({required this.post});

  final PostDto post;

  @override
  ConsumerState<_EditMemorySheet> createState() => _EditMemorySheetState();
}

class _EditMemorySheetState extends ConsumerState<_EditMemorySheet> {
  late final TextEditingController _captionController;
  late String _visibility;
  bool _saving = false;
  String? _error;
  final _updateIdempotencyKey = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.post.caption ?? '');
    _visibility = widget.post.visibility;
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit memory',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _captionController,
                enabled: !_saving,
                minLines: 3,
                maxLines: 5,
                maxLength: 2000,
                decoration: const InputDecoration(
                  labelText: 'Caption (optional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              Text('Audience', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'PET_MEMBERS',
                    icon: Icon(Icons.people_outline),
                    label: Text('Pet members'),
                  ),
                  ButtonSegment(
                    value: 'PRIVATE',
                    icon: Icon(Icons.lock_outline),
                    label: Text('Only me'),
                  ),
                ],
                selected: {_visibility},
                onSelectionChanged: _saving
                    ? null
                    : (selection) {
                        setState(() => _visibility = selection.single);
                      },
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: const TextStyle(color: PawketColors.danger),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: PawketColors.brand,
                ),
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref
          .read(postRepositoryProvider)
          .updatePost(
            widget.post.id,
            UpdatePostRequest(
              caption: _captionController.text,
              visibility: _visibility,
              version: widget.post.version ?? 0,
            ),
            idempotencyKey: _updateIdempotencyKey,
          );
      if (mounted) Navigator.pop(context, updated);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save these changes. Please try again.';
      });
    }
  }
}

void _refreshPostLists(WidgetRef ref, Iterable<String> petIds) {
  for (final petId in petIds) {
    ref.invalidate(petFeedProvider(petId));
    ref.invalidate(petMemoriesProvider(petId));
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
