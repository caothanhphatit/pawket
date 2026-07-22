import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/pawket_theme.dart';
import '../../memberships/application/membership_providers.dart';
import '../application/milestone_providers.dart';
import '../data/milestone_dto.dart';

class MilestoneSection extends ConsumerStatefulWidget {
  const MilestoneSection({required this.petId, super.key});

  final String petId;

  @override
  ConsumerState<MilestoneSection> createState() => _MilestoneSectionState();
}

class _MilestoneSectionState extends ConsumerState<MilestoneSection> {
  final Set<String> _deletingIds = {};

  @override
  Widget build(BuildContext context) {
    final milestones = ref.watch(petMilestonesProvider(widget.petId));
    final members = ref.watch(petMembersProvider(widget.petId));
    final account = ref.watch(membershipCurrentAccountProvider);
    final currentUserId = account.when(
      data: (value) => value.id,
      error: (_, _) => null,
      loading: () => null,
    );
    final currentRole = members.when(
      data: (items) => items
          .where((member) => member.userId == currentUserId)
          .firstOrNull
          ?.role,
      error: (_, _) => null,
      loading: () => null,
    );
    final canCreate = currentRole == 'OWNER' || currentRole == 'CARETAKER';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Milestones',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            if (canCreate)
              TextButton.icon(
                onPressed: () =>
                    context.push('/pets/${widget.petId}/milestones/new'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        milestones.when(
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (_, _) => Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_off_outlined),
              title: const Text('Could not load milestones'),
              trailing: TextButton(
                onPressed: () =>
                    ref.invalidate(petMilestonesProvider(widget.petId)),
                child: const Text('Retry'),
              ),
            ),
          ),
          data: (items) => _buildMilestones(
            context,
            items,
            currentUserId: currentUserId,
            isOwner: currentRole == 'OWNER',
            canCreate: canCreate,
          ),
        ),
      ],
    );
  }

  Widget _buildMilestones(
    BuildContext context,
    List<MilestoneDto> items, {
    required String? currentUserId,
    required bool isOwner,
    required bool canCreate,
  }) {
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const CircleAvatar(
                backgroundColor: PawketColors.surfaceStrong,
                child: Icon(Icons.flag_outlined, color: PawketColors.brand),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Birthdays, home days and first adventures live here.',
                ),
              ),
              if (canCreate)
                IconButton(
                  tooltip: 'Add milestone',
                  onPressed: () =>
                      context.push('/pets/${widget.petId}/milestones/new'),
                  icon: const Icon(Icons.add),
                ),
            ],
          ),
        ),
      );
    }

    final today = _dateOnly(DateTime.now());
    final upcoming =
        items
            .where((item) => !_dateOnly(item.occurredOn).isBefore(today))
            .toList()
          ..sort((a, b) => a.occurredOn.compareTo(b.occurredOn));
    final recent =
        items
            .where((item) => _dateOnly(item.occurredOn).isBefore(today))
            .toList()
          ..sort((a, b) => b.occurredOn.compareTo(a.occurredOn));
    final visible = [...upcoming.take(3), ...recent.take(3)];

    return Card(
      child: Column(
        children: [
          for (var index = 0; index < visible.length; index++) ...[
            _MilestoneTile(
              milestone: visible[index],
              upcoming: !_dateOnly(visible[index].occurredOn).isBefore(today),
              canDelete:
                  isOwner || visible[index].creatorUserId == currentUserId,
              deleting: _deletingIds.contains(visible[index].id),
              onDelete: () => _confirmDelete(visible[index]),
            ),
            if (index != visible.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(MilestoneDto milestone) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${milestone.title}?'),
        content: const Text('This removes the milestone from the pet profile.'),
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

    setState(() => _deletingIds.add(milestone.id));
    try {
      await ref
          .read(milestoneRepositoryProvider)
          .deleteMilestone(widget.petId, milestone.id);
      ref.invalidate(petMilestonesProvider(widget.petId));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete this milestone.')),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingIds.remove(milestone.id));
    }
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({
    required this.milestone,
    required this.upcoming,
    required this.canDelete,
    required this.deleting,
    required this.onDelete,
  });

  final MilestoneDto milestone;
  final bool upcoming;
  final bool canDelete;
  final bool deleting;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      leading: CircleAvatar(
        backgroundColor: upcoming
            ? PawketColors.surfaceStrong
            : PawketColors.canvas,
        foregroundColor: upcoming ? PawketColors.brand : PawketColors.inkMuted,
        child: Icon(_iconFor(milestone.type)),
      ),
      title: Text(
        milestone.title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [
          _friendlyDate(milestone.occurredOn),
          if (milestone.note case final note? when note.isNotEmpty) note,
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: deleting
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : canDelete
          ? IconButton(
              tooltip: 'Delete milestone',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            )
          : null,
    );
  }

  static IconData _iconFor(MilestoneType type) => switch (type) {
    MilestoneType.birthday => Icons.cake_outlined,
    MilestoneType.homeDay => Icons.home_outlined,
    MilestoneType.firstTrip => Icons.explore_outlined,
    MilestoneType.custom => Icons.flag_outlined,
  };
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _friendlyDate(DateTime value) {
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
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}
