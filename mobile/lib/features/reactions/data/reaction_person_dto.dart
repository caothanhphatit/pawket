import '../../../core/network/api_models.dart';

class ReactionPersonDto {
  const ReactionPersonDto({
    required this.userId,
    required this.displayName,
    required this.type,
    this.avatarMediaId,
  });

  factory ReactionPersonDto.fromJson(JsonMap json) => ReactionPersonDto(
    userId: json['userId'] as String,
    displayName: json['displayName'] as String? ?? 'Pawket member',
    type: json['type'] as String,
    avatarMediaId: json['avatarMediaId'] as String?,
  );

  final String userId;
  final String displayName;
  final String type;
  final String? avatarMediaId;
}
