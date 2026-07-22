import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/notification_providers.dart';

class NotificationBadge extends ConsumerWidget {
  const NotificationBadge({
    this.icon = Icons.notifications_outlined,
    super.key,
  });

  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadNotificationCountProvider).value ?? 0;
    final child = Icon(icon);
    if (count <= 0) return child;
    return Badge.count(count: count > 99 ? 99 : count, child: child);
  }
}
