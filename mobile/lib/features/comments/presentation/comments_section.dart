import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/bootstrap/app_providers.dart';
import '../../../app/theme/pawket_theme.dart';
import '../../safety/application/safety_providers.dart';
import '../application/comment_providers.dart';
import '../data/comment_dto.dart';

class CommentsSection extends ConsumerStatefulWidget {
  const CommentsSection({required this.postId, super.key});

  final String postId;

  @override
  ConsumerState<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<CommentsSection> {
  final _controller = TextEditingController();
  bool _posting = false;
  String? _error;
  String _idempotencyKey = const Uuid().v4();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(postCommentsProvider(widget.postId));
    final currentUserId = ref.watch(apiConfigProvider).devUserId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Comments', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(width: 8),
            Text(
              comments.value?.items.length.toString() ?? '…',
              style: const TextStyle(color: PawketColors.inkMuted),
            ),
          ],
        ),
        const SizedBox(height: 14),
        comments.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => _CommentMessage(
            message: 'Could not load comments.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(postCommentsProvider(widget.postId)),
          ),
          data: (page) => page.items.isEmpty
              ? const _CommentMessage(
                  message: 'No comments yet. Leave the first one.',
                )
              : Column(
                  children: [
                    for (final comment in page.items)
                      _CommentTile(
                        comment: comment,
                        canManage: comment.canManage(currentUserId),
                        onEdit: () => _edit(comment),
                        onDelete: () => _delete(comment),
                        onReport: () => _report(comment),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          enabled: !_posting,
          minLines: 1,
          maxLines: 4,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'Write a comment…',
            counterText: '',
            errorText: _error,
            suffixIcon: IconButton(
              onPressed: _posting ? null : _create,
              tooltip: 'Post comment',
              icon: _posting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_outlined),
            ),
          ),
          onSubmitted: (_) => _create(),
        ),
      ],
    );
  }

  Future<void> _create() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _posting) return;
    setState(() {
      _posting = true;
      _error = null;
    });
    try {
      await ref
          .read(commentRepositoryProvider)
          .create(
            widget.postId,
            CreateCommentRequest(body),
            idempotencyKey: _idempotencyKey,
          );
      _controller.clear();
      _idempotencyKey = const Uuid().v4();
      ref.invalidate(postCommentsProvider(widget.postId));
      if (mounted) setState(() => _posting = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _posting = false;
        _error = 'Could not post. Tap send to retry.';
      });
    }
  }

  Future<void> _edit(CommentDto comment) async {
    final updated = await showDialog<CommentDto>(
      context: context,
      builder: (_) => _EditCommentDialog(comment: comment),
    );
    if (updated != null) ref.invalidate(postCommentsProvider(widget.postId));
  }

  Future<void> _delete(CommentDto comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This comment will be removed permanently.'),
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
    try {
      await ref.read(commentRepositoryProvider).delete(comment.id);
      ref.invalidate(postCommentsProvider(widget.postId));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete this comment.')),
      );
    }
  }

  Future<void> _report(CommentDto comment) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Why are you reporting this comment?')),
            for (final entry in const {
              'SPAM': 'Spam',
              'HARASSMENT': 'Harassment',
              'PRIVACY': 'Privacy concern',
              'INAPPROPRIATE': 'Inappropriate content',
              'OTHER': 'Other',
            }.entries)
              ListTile(
                title: Text(entry.value),
                onTap: () => Navigator.pop(context, entry.key),
              ),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;
    try {
      await ref
          .read(safetyRepositoryProvider)
          .report(targetType: 'COMMENT', targetId: comment.id, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted for review.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not submit this report.')),
        );
      }
    }
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
    required this.onReport,
  });

  final CommentDto comment;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: PawketColors.surfaceStrong,
            child: Text(
              comment.author.displayName.characters.firstOrNull
                      ?.toUpperCase() ??
                  '?',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.author.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      _timeLabel(comment.createdAt),
                      style: const TextStyle(
                        color: PawketColors.inkMuted,
                        fontSize: 12,
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Comment actions',
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                        if (value == 'report') onReport();
                      },
                      itemBuilder: (_) => [
                        if (canManage)
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                        if (canManage)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        const PopupMenuItem(
                          value: 'report',
                          child: Text('Report'),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(comment.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditCommentDialog extends ConsumerStatefulWidget {
  const _EditCommentDialog({required this.comment});
  final CommentDto comment;

  @override
  ConsumerState<_EditCommentDialog> createState() => _EditCommentDialogState();
}

class _EditCommentDialogState extends ConsumerState<_EditCommentDialog> {
  late final TextEditingController _controller;
  bool _saving = false;
  String? _error;
  final _idempotencyKey = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.comment.body);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit comment'),
      content: TextField(
        controller: _controller,
        enabled: !_saving,
        minLines: 2,
        maxLines: 5,
        maxLength: 500,
        decoration: InputDecoration(errorText: _error),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final body = _controller.text.trim();
    if (body.isEmpty) {
      setState(() => _error = 'Comment cannot be empty.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref
          .read(commentRepositoryProvider)
          .update(
            widget.comment.id,
            UpdateCommentRequest(body: body, version: widget.comment.version),
            idempotencyKey: _idempotencyKey,
          );
      if (mounted) Navigator.pop(context, updated);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save. Please try again.';
      });
    }
  }
}

class _CommentMessage extends StatelessWidget {
  const _CommentMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: PawketColors.inkMuted),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

String _timeLabel(DateTime value) {
  final difference = DateTime.now().difference(value.toLocal());
  if (difference.inMinutes < 1) return 'now';
  if (difference.inHours < 1) return '${difference.inMinutes}m';
  if (difference.inDays < 1) return '${difference.inHours}h';
  return '${difference.inDays}d';
}
