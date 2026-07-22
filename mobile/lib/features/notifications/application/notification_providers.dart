import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/app_providers.dart';
import '../../../core/network/api_models.dart';
import '../data/notification_dto.dart';
import '../data/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return RemoteNotificationRepository(ref.watch(apiClientProvider));
});

final notificationsProvider =
    FutureProvider.autoDispose<CursorPage<PawketNotificationDto>>((ref) {
      return ref.watch(notificationRepositoryProvider).list();
    });

final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((ref) {
  final refresh = Timer(const Duration(seconds: 30), ref.invalidateSelf);
  ref.onDispose(refresh.cancel);
  return ref.watch(notificationRepositoryProvider).unreadCount();
});
