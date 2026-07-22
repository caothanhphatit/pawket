import '../../../core/network/api_client.dart';
import '../../../core/network/api_models.dart';
import 'notification_dto.dart';

abstract interface class NotificationRepository {
  Future<CursorPage<PawketNotificationDto>> list();
  Future<int> unreadCount();
  Future<void> markRead(String notificationId);
  Future<void> markAllRead();
}

class RemoteNotificationRepository implements NotificationRepository {
  const RemoteNotificationRepository(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<CursorPage<PawketNotificationDto>> list() async {
    final response = await _apiClient.get<Object>(
      '/notifications',
      queryParameters: const {'limit': 100},
    );
    final root = requireJsonMap(response.data);
    final items = requireJsonList(root['data'], context: 'notifications');
    final page = root['page'] is Map
        ? requireJsonMap(root['page'], context: 'notification page')
        : const <String, dynamic>{};
    return CursorPage(
      items: items.map(PawketNotificationDto.fromJson).toList(growable: false),
      nextCursor: page['nextCursor'] as String?,
      hasMore: page['hasMore'] as bool? ?? false,
    );
  }

  @override
  Future<int> unreadCount() async {
    final response = await _apiClient.get<Object>(
      '/notifications/unread-count',
    );
    final data = unwrapData(response.data);
    if (data is num) return data.toInt();
    final json = requireJsonMap(data, context: 'unread count');
    return (json['count'] as num? ?? json['unreadCount'] as num? ?? 0).toInt();
  }

  @override
  Future<void> markRead(String notificationId) async {
    await _apiClient.post<void>('/notifications/$notificationId/read');
  }

  @override
  Future<void> markAllRead() async {
    await _apiClient.post<void>('/notifications/read-all');
  }
}
