import '../../../core/network/api_models.dart';

class MemberDto {
  const MemberDto({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
    this.avatarMediaId,
  });

  factory MemberDto.fromJson(JsonMap json) => MemberDto(
    userId: json['userId'] as String,
    displayName: json['displayName'] as String? ?? 'Pawket member',
    avatarMediaId: json['avatarMediaId'] as String?,
    role: json['role'] as String? ?? 'FOLLOWER',
    joinedAt: DateTime.parse(json['joinedAt'] as String).toUtc(),
  );

  final String userId;
  final String displayName;
  final String? avatarMediaId;
  final String role;
  final DateTime joinedAt;
}
