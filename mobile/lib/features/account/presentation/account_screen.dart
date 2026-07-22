import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pawket_mobile/app/bootstrap/app_providers.dart';
import 'package:pawket_mobile/app/theme/pawket_theme.dart';
import 'package:pawket_mobile/app/widgets/pawket_scaffold.dart';
import 'package:pawket_mobile/features/pets/application/pet_providers.dart';
import 'package:pawket_mobile/features/pets/presentation/widgets/pet_avatar.dart';
import 'package:pawket_mobile/features/notifications/presentation/notification_badge.dart';

import '../data/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return RemoteAccountRepository(ref.watch(apiClientProvider));
});

final currentAccountProvider = FutureProvider.autoDispose<AccountDto>((ref) {
  return ref.watch(accountRepositoryProvider).getCurrent();
});

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pets = ref.watch(petsProvider);
    final account = ref.watch(currentAccountProvider);

    return PawketScaffold(
      currentIndex: -1,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 120),
        children: [
          Text('Your corner', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          const Text(
            'Profiles, people and the quiet settings behind your archive.',
            style: TextStyle(color: PawketColors.inkMuted, fontSize: 16),
          ),
          const SizedBox(height: 28),
          account.when(
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (_, _) => Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_off_outlined),
                title: const Text('Could not load your account'),
                trailing: TextButton(
                  onPressed: () => ref.invalidate(currentAccountProvider),
                  child: const Text('Retry'),
                ),
              ),
            ),
            data: (value) => Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: PawketColors.surfaceStrong,
                      foregroundColor: PawketColors.ink,
                      backgroundImage: value.avatarUrl == null
                          ? null
                          : NetworkImage(value.avatarUrl.toString()),
                      child: value.avatarUrl == null
                          ? Text(
                              value.displayName.characters.first.toUpperCase(),
                              style: const TextStyle(fontSize: 24),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value.displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'Pet archivist',
                            style: TextStyle(color: PawketColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('YOUR PETS', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 10),
          for (final pet in pets)
            Card(
              child: ListTile(
                leading: PetAvatar(pet: pet),
                title: Text(pet.name),
                subtitle: Text('${pet.speciesLabel} · Owner'),
                trailing: pet.id == ref.watch(activePetIdProvider)
                    ? const Icon(Icons.check, color: PawketColors.leaf)
                    : null,
              ),
            ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const NotificationBadge(),
                  title: const Text('Notification inbox'),
                  subtitle: const Text('Comments, reactions and pet updates'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/notifications'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.schedule_outlined),
                  title: const Text('Daily reminder'),
                  subtitle: const Text('Choose when Pawket reminds you'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/reminders'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Export Pawket data'),
                  subtitle: const Text('Portable JSON copy'),
                  trailing: const Icon(Icons.ios_share_outlined),
                  onTap: () => _exportData(context, ref),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.shield_outlined),
                  title: Text('Privacy and permissions'),
                  subtitle: Text('Managed per pet for now'),
                  enabled: false,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.block_outlined),
                  title: const Text('Blocked members'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/blocked'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _exportData(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final response = await ref
        .read(apiClientProvider)
        .get<Object>('/users/me/export');
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/pawket-data-export.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(response.data),
      flush: true,
    );
    if (!context.mounted) return;
    final box = context.findRenderObject()! as RenderBox;
    await SharePlus.instance.share(
      ShareParams(
        text: 'My Pawket data export',
        files: [XFile(file.path, mimeType: 'application/json')],
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Could not export Pawket data.')),
    );
  }
}
