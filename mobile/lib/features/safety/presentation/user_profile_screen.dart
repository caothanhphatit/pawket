import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/bootstrap/app_providers.dart';
import '../../../app/theme/pawket_theme.dart';
import '../../feed/application/feed_providers.dart';
import '../application/safety_providers.dart';
import '../data/safety_repository.dart';

class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({required this.userId, super.key});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider(userId));
    final isCurrentUser = ref.watch(apiConfigProvider).devUserId == userId;
    return Scaffold(
      appBar: AppBar(title: const Text('Member profile')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('This profile is not available.')),
        data: (value) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: PawketColors.surfaceStrong,
              backgroundImage: value.avatarUrl == null
                  ? null
                  : NetworkImage(value.avatarUrl.toString()),
              child: value.avatarUrl == null
                  ? Text(
                      value.displayName.characters.firstOrNull?.toUpperCase() ??
                          '?',
                      style: const TextStyle(fontSize: 28),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              value.displayName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 24),
            Text('SHARED PETS', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Card(
              child: value.sharedPets.isEmpty
                  ? const ListTile(title: Text('No shared pets yet.'))
                  : Column(
                      children: [
                        for (final pet in value.sharedPets)
                          ListTile(
                            leading: const Icon(Icons.pets),
                            title: Text(pet.name),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              'RECENT SHARED MEMORIES',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: value.recentPosts.isEmpty
                  ? const ListTile(title: Text('No shared memories yet.'))
                  : Column(
                      children: [
                        for (final post in value.recentPosts)
                          ListTile(
                            leading: const Icon(Icons.photo_outlined),
                            title: Text(
                              post.caption?.trim().isNotEmpty == true
                                  ? post.caption!
                                  : 'Pet memory',
                            ),
                            subtitle: Text(_date(post.capturedAt)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/posts/${post.id}'),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            if (!isCurrentUser)
              OutlinedButton.icon(
                onPressed: () => _block(context, ref, value),
                icon: const Icon(Icons.block),
                label: const Text('Block this member'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: PawketColors.danger,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _block(
    BuildContext context,
    WidgetRef ref,
    UserProfileDto profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block ${profile.displayName}?'),
        content: const Text(
          'You will no longer see each other’s member-visible activity.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Block'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(safetyRepositoryProvider).blockUser(profile.id);
    ref.invalidate(blockedUsersProvider);
    ref.invalidate(petFeedProvider);
    if (context.mounted) Navigator.pop(context);
  }
}

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Blocked members')),
    body: ref
        .watch(blockedUsersProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const Center(child: Text('Could not load blocked members.')),
          data: (items) => items.isEmpty
              ? const Center(child: Text('No blocked members.'))
              : ListView(
                  children: [
                    for (final user in items)
                      ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_outline),
                        ),
                        title: Text(user.displayName),
                        trailing: TextButton(
                          onPressed: () async {
                            await ref
                                .read(safetyRepositoryProvider)
                                .unblockUser(user.userId);
                            ref.invalidate(blockedUsersProvider);
                            ref.invalidate(petFeedProvider);
                          },
                          child: const Text('Unblock'),
                        ),
                      ),
                  ],
                ),
        ),
  );
}

String _date(DateTime value) {
  final d = value.toLocal();
  return '${d.day}/${d.month}/${d.year}';
}
