import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/pawket_theme.dart';
import '../../../app/widgets/pawket_scaffold.dart';
import '../../feed/application/feed_providers.dart';
import '../../memberships/application/membership_providers.dart';
import '../../milestones/application/milestone_providers.dart';
import '../../milestones/presentation/milestone_section.dart';
import '../../posts/data/post_dto.dart';
import '../application/pet_providers.dart';
import '../data/pet_dto.dart';
import '../domain/pet.dart';
import 'widgets/pet_avatar.dart';

class PetProfileScreen extends ConsumerWidget {
  const PetProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = ref.watch(activePetProvider);
    final loadState = ref.watch(petLoadStateProvider);

    return PawketScaffold(
      currentIndex: 1,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: pet == null
              ? _NoPetProfile(
                  loading: loadState.isLoading,
                  hasError: loadState.error != null,
                  onRetry: () => ref.read(petsProvider.notifier).refresh(),
                )
              : _ProfileContent(pet: pet),
        ),
      ),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.pet});

  final Pet pet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(petDetailsProvider(pet.id));
    final memories = ref.watch(petMemoriesProvider(pet.id));
    final members = ref.watch(petMembersProvider(pet.id));
    final detail = details.value;
    final posts = memories.value?.items ?? const <PostDto>[];

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(petDetailsProvider(pet.id));
        ref.invalidate(petMemoriesProvider(pet.id));
        ref.invalidate(petMembersProvider(pet.id));
        ref.invalidate(petMilestonesProvider(pet.id));
        await ref.read(petsProvider.notifier).refresh();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Profile',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.go('/you'),
                    tooltip: 'Open settings',
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: SliverToBoxAdapter(child: MilestoneSection(petId: pet.id)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  PetAvatar(pet: pet, radius: 54, selected: true),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _showPetSwitcher(context, ref),
                    style: TextButton.styleFrom(
                      foregroundColor: PawketColors.ink,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pet.name,
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more),
                      ],
                    ),
                  ),
                  Text(
                    _identityLabel(pet, detail),
                    style: const TextStyle(
                      color: PawketColors.inkMuted,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pet.homeSince == null
                        ? 'Add home date'
                        : 'Home since ${_monthName(pet.homeSince!.month)} ${pet.homeSince!.year}',
                    style: const TextStyle(color: PawketColors.inkMuted),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _ProfileStat(
                          value: _daysAtHome(pet.homeSince),
                          label: 'Days',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ProfileStat(
                          value: memories.isLoading ? '…' : '${posts.length}',
                          label: 'Memories',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ProfileStat(
                          value: members.when(
                            data: (items) => '${items.length}',
                            loading: () => '…',
                            error: (_, _) => '—',
                          ),
                          label: 'Members',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'ABOUT',
                          style: TextStyle(
                            color: PawketColors.inkMuted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: detail == null
                            ? null
                            : () => context.push('/pets/${pet.id}/edit'),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                  Card(
                    child: details.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Some profile details could not be loaded.',
                          style: TextStyle(color: PawketColors.inkMuted),
                        ),
                      ),
                      data: (value) => Column(
                        children: [
                          _AboutRow(
                            label: 'Birthday',
                            value: _dateValue(value?.birthDate),
                          ),
                          const Divider(height: 1),
                          _AboutRow(
                            label: 'Breed',
                            value: _textValue(value?.breed),
                          ),
                          const Divider(height: 1),
                          _AboutRow(
                            label: 'Gender',
                            value: _textValue(value?.gender),
                          ),
                          const Divider(height: 1),
                          _AboutRow(
                            label: 'Family',
                            value: 'Members',
                            onTap: () =>
                                context.push('/pets/${pet.id}/members'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => context.push('/pets/${pet.id}/invite'),
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: const Text('Invite family'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Text(
                    'Memories',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    memories.isLoading ? '…' : '${posts.length}',
                    style: const TextStyle(color: PawketColors.inkMuted),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _showMemoryTools(context),
                    tooltip: 'Memory tools',
                    icon: const Icon(Icons.more_horiz),
                  ),
                ],
              ),
            ),
          ),
          if (memories.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (memories.hasError)
            SliverToBoxAdapter(
              child: _MemoriesMessage(
                icon: Icons.cloud_off_outlined,
                message: 'Could not load memories.',
                onRetry: () => ref.invalidate(petMemoriesProvider(pet.id)),
              ),
            )
          else if (posts.isEmpty)
            const SliverToBoxAdapter(
              child: _MemoriesMessage(
                icon: Icons.add_a_photo_outlined,
                message: 'The first chapter is ready when you are.',
              ),
            )
          else
            SliverLayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.crossAxisExtent >= 620 ? 4 : 3;
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverGrid.builder(
                    itemCount: posts.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 3,
                      mainAxisSpacing: 3,
                    ),
                    itemBuilder: (context, index) =>
                        _MemoryTile(post: posts[index], index: index),
                  ),
                );
              },
            ),
        ],
      ),
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
            height: MediaQuery.sizeOf(context).height * .64,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                Text(
                  'Choose a pet',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                for (final candidate in pets)
                  ListTile(
                    leading: PetAvatar(pet: candidate),
                    title: Text(candidate.name),
                    subtitle: Text(candidate.speciesLabel),
                    trailing: activeId == candidate.id
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      ref
                          .read(activePetIdProvider.notifier)
                          .select(candidate.id);
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

  Future<void> _showMemoryTools(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Memory calendar'),
                subtitle: const Text('Browse the days you remembered'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/calendar');
                },
              ),
              ListTile(
                leading: const Icon(Icons.auto_awesome_outlined),
                title: const Text('Weekly recap'),
                subtitle: const Text('Create and share the last seven days'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/recap');
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_photo_alternate_outlined),
                title: const Text('Add old memories'),
                subtitle: const Text(
                  'Import photos without changing the camera',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  context.push('/memories/import');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      decoration: BoxDecoration(
        color: PawketColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PawketColors.outline),
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: PawketColors.inkMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: PawketColors.inkMuted),
              ),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

class _MemoryTile extends StatelessWidget {
  const _MemoryTile({required this.post, required this.index});

  final PostDto post;
  final int index;

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFF71867B),
      Color(0xFFD7B58C),
      Color(0xFFC45132),
      Color(0xFF2E6B57),
      Color(0xFF8C735B),
      Color(0xFF56718D),
    ];
    final media = post.media.firstOrNull;

    return Semantics(
      button: true,
      label: index == 0 ? 'Newest memory' : 'Memory ${index + 1}',
      child: InkWell(
        onTap: () => context.push('/posts/${post.id}', extra: post),
        child: media == null
            ? ColoredBox(
                color: colors[index % colors.length],
                child: const Center(
                  child: Icon(Icons.pets, color: Colors.white54, size: 38),
                ),
              )
            : Image.network(
                (media.thumbnailUrl ?? media.url).toString(),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: colors[index % colors.length],
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
      ),
    );
  }
}

class _MemoriesMessage extends StatelessWidget {
  const _MemoriesMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        children: [
          Icon(icon, size: 36, color: PawketColors.inkMuted),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: PawketColors.inkMuted)),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    );
  }
}

class _NoPetProfile extends StatelessWidget {
  const _NoPetProfile({
    required this.loading,
    required this.hasError,
    required this.onRetry,
  });

  final bool loading;
  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasError ? Icons.cloud_off_outlined : Icons.pets_outlined,
            size: 42,
            color: PawketColors.inkMuted,
          ),
          const SizedBox(height: 12),
          Text(
            hasError
                ? 'Could not load profiles'
                : 'Create a pet to start a profile.',
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: hasError ? onRetry : () => context.push('/pets/new'),
            child: Text(hasError ? 'Try again' : 'Create pet'),
          ),
        ],
      ),
    );
  }
}

String _identityLabel(Pet pet, PetDto? detail) {
  final birthDate = detail?.birthDate;
  if (birthDate == null) return pet.speciesLabel;
  final now = DateTime.now();
  var years = now.year - birthDate.year;
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    years--;
  }
  return '${pet.speciesLabel} · ${years <= 0 ? 'Under 1 year old' : '$years years old'}';
}

String _daysAtHome(DateTime? value) {
  if (value == null) return '—';
  return '${DateTime.now().difference(value).inDays.clamp(0, 99999)}';
}

String _dateValue(DateTime? value) {
  if (value == null) return 'Not added';
  return '${value.day} ${_monthName(value.month)} ${value.year}';
}

String _textValue(String? value) {
  return value == null || value.trim().isEmpty ? 'Not added' : value;
}

String _monthName(int month) {
  const names = [
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
  return names[month - 1];
}
