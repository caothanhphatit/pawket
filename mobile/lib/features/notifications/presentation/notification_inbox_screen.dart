import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/pawket_theme.dart';
import '../../pets/application/pet_providers.dart';
import '../application/notification_providers.dart';
import '../data/notification_dto.dart';

class NotificationInboxScreen extends ConsumerStatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  ConsumerState<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState
    extends ConsumerState<NotificationInboxScreen> {
  final _locallyRead = <String>{};
  bool _markingAll = false;

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);
    final hasUnread =
        notifications.value?.items.any(
          (item) => !item.isRead && !_locallyRead.contains(item.id),
        ) ??
        false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: hasUnread && !_markingAll ? _markAllRead : null,
            child: _markingAll
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Read all'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(unreadNotificationCountProvider);
          final _ = await ref.refresh(notificationsProvider.future);
        },
        child: notifications.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 280),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (_, _) => _InboxMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load notifications',
            body: 'Check the connection and try again.',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(notificationsProvider),
          ),
          data: (page) => page.items.isEmpty
              ? const _InboxMessage(
                  icon: Icons.notifications_none_outlined,
                  title: 'All quiet',
                  body: 'Comments, reactions and pet updates will appear here.',
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: page.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notification = page.items[index];
                    return _NotificationTile(
                      notification: notification,
                      isRead:
                          notification.isRead ||
                          _locallyRead.contains(notification.id),
                      onTap: () => _open(notification),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _open(PawketNotificationDto notification) async {
    if (!notification.isRead && !_locallyRead.contains(notification.id)) {
      setState(() => _locallyRead.add(notification.id));
      try {
        await ref
            .read(notificationRepositoryProvider)
            .markRead(notification.id);
        ref.invalidate(unreadNotificationCountProvider);
      } catch (_) {
        if (mounted) setState(() => _locallyRead.remove(notification.id));
      }
    }
    if (!mounted) return;

    final route = notificationRoute(notification);
    if (route == null) return;
    final petId = notification.petId;
    if (petId != null && ref.read(petsProvider).any((pet) => pet.id == petId)) {
      ref.read(activePetIdProvider.notifier).select(petId);
    }
    if (route == '/profile') {
      context.go(route);
    } else {
      context.push(route);
    }
  }

  Future<void> _markAllRead() async {
    setState(() => _markingAll = true);
    try {
      await ref.read(notificationRepositoryProvider).markAllRead();
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationCountProvider);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not mark notifications as read.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _markingAll = false);
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  final PawketNotificationDto notification;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isRead ? null : PawketColors.surfaceStrong,
      child: ListTile(
        onTap: onTap,
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              backgroundColor: PawketColors.surface,
              child: Icon(_notificationIcon(notification.type)),
            ),
            if (!isRead)
              const Positioned(
                right: -1,
                top: -1,
                child: CircleAvatar(
                  radius: 5,
                  backgroundColor: PawketColors.brand,
                ),
              ),
          ],
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.w500 : FontWeight.w800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notification.body.isNotEmpty) Text(notification.body),
            const SizedBox(height: 4),
            Text(
              _relativeTime(notification.createdAt),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: notificationRoute(notification) == null
            ? null
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _InboxMessage extends StatelessWidget {
  const _InboxMessage({
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 180),
        Icon(icon, size: 44, color: PawketColors.inkMuted),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 6),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: PawketColors.inkMuted),
        ),
        if (actionLabel != null) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ),
        ],
      ],
    );
  }
}

IconData _notificationIcon(String type) {
  final normalized = type.toUpperCase();
  if (normalized.contains('COMMENT')) return Icons.chat_bubble_outline;
  if (normalized.contains('REACTION')) return Icons.favorite_outline;
  if (normalized.contains('INVIT')) return Icons.person_add_alt_1_outlined;
  if (normalized.contains('PET')) return Icons.pets_outlined;
  return Icons.notifications_outlined;
}

String _relativeTime(DateTime value) {
  final difference = DateTime.now().difference(value.toLocal());
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes}m ago';
  if (difference.inDays < 1) return '${difference.inHours}h ago';
  return '${difference.inDays}d ago';
}
