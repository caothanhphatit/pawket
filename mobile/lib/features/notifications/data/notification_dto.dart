import '../../../core/network/api_models.dart';

class NotificationActorDto {
  const NotificationActorDto({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  factory NotificationActorDto.fromJson(JsonMap json) => NotificationActorDto(
    id: json['id'] as String? ?? '',
    displayName: json['displayName'] as String? ?? 'Pawket member',
    avatarUrl: json['avatarUrl'] as String?,
  );

  final String id;
  final String displayName;
  final String? avatarUrl;
}

class PawketNotificationDto {
  const PawketNotificationDto({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.postId,
    this.petId,
    this.invitationId,
    this.actor,
  });

  factory PawketNotificationDto.fromJson(JsonMap json) {
    final actor = json['actor'];
    final parsedActor = actor is Map
        ? NotificationActorDto.fromJson(actor.cast<String, dynamic>())
        : null;
    final type = json['type'] as String? ?? 'UPDATE';
    final target = json['target'] is Map
        ? (json['target'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    return PawketNotificationDto(
      id: json['id'] as String,
      type: type,
      title: json['title'] as String? ?? _defaultTitle(type, parsedActor),
      body:
          json['body'] as String? ??
          json['message'] as String? ??
          _defaultBody(type),
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      readAt: DateTime.tryParse(json['readAt'] as String? ?? '')?.toUtc(),
      postId: json['postId'] as String? ?? target['postId'] as String?,
      petId: json['petId'] as String? ?? target['petId'] as String?,
      invitationId:
          json['invitationId'] as String? ?? target['invitationId'] as String?,
      actor: parsedActor,
    );
  }

  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? postId;
  final String? petId;
  final String? invitationId;
  final NotificationActorDto? actor;

  bool get isRead => readAt != null;
}

String _defaultTitle(String type, NotificationActorDto? actor) {
  final name = actor?.displayName ?? 'A Pawket member';
  return switch (type.toUpperCase()) {
    'COMMENT' => '$name commented on your memory',
    'REACTION' => '$name reacted to your memory',
    'NEW_POST' => '$name shared a new memory',
    'INVITATION_ACCEPTED' => '$name joined a pet profile',
    _ => 'Pawket update',
  };
}

String _defaultBody(String type) => switch (type.toUpperCase()) {
  'COMMENT' => 'Open the memory to join the conversation.',
  'REACTION' => 'Open the memory to see the reaction.',
  'NEW_POST' => 'A new moment was added to a pet you follow.',
  'INVITATION_ACCEPTED' => 'Open the pet profile to see the family.',
  _ => '',
};

String? notificationRoute(PawketNotificationDto notification) {
  if (notification.postId != null) return '/posts/${notification.postId}';
  if (notification.petId != null) return '/profile';
  if (notification.invitationId != null) {
    return '/invite/${notification.invitationId}';
  }
  return null;
}
