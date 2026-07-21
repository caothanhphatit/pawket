import '../../../core/network/api_models.dart';

enum PetMemberRole {
  owner('OWNER'),
  caretaker('CARETAKER'),
  follower('FOLLOWER');

  const PetMemberRole(this.wireValue);
  final String wireValue;

  static PetMemberRole fromWire(String value) =>
      PetMemberRole.values.firstWhere(
        (role) => role.wireValue == value,
        orElse: () => throw FormatException('Unknown member role: $value'),
      );
}

class InvitationDto {
  const InvitationDto({
    required this.id,
    required this.petId,
    required this.petName,
    required this.requestedRole,
    required this.status,
    required this.expiresAt,
    this.inviterDisplayName,
    this.invitationUrl,
  });

  factory InvitationDto.fromJson(
    JsonMap json, {
    String? fallbackPetId,
    PetMemberRole? fallbackRole,
  }) => InvitationDto(
    id: json['id'] as String,
    petId: json['petId'] as String? ?? fallbackPetId ?? '',
    petName: json['petName'] as String? ?? 'your pet',
    requestedRole: PetMemberRole.fromWire(
      json['requestedRole'] as String? ??
          json['role'] as String? ??
          fallbackRole?.wireValue ??
          'FOLLOWER',
    ),
    status: json['status'] as String? ?? 'PENDING',
    expiresAt: DateTime.parse(json['expiresAt'] as String).toUtc(),
    inviterDisplayName:
        json['inviterDisplayName'] as String? ?? json['inviterName'] as String?,
    invitationUrl: switch (json['invitationUrl']) {
      final String url => Uri.parse(url),
      _ => switch (json['token']) {
        final String token => _inviteUrl(token),
        _ => null,
      },
    },
  );

  final String id;
  final String petId;
  final String petName;
  final PetMemberRole requestedRole;
  final String status;
  final DateTime expiresAt;
  final String? inviterDisplayName;
  final Uri? invitationUrl;
}

class CreateInvitationRequest {
  const CreateInvitationRequest({
    required this.requestedRole,
    this.expiresInDays = 7,
  });

  final PetMemberRole requestedRole;
  final int expiresInDays;

  JsonMap toJson() => {
    'role': requestedRole.wireValue,
    'expiresInDays': expiresInDays,
  };
}

Uri _inviteUrl(String token) {
  final base = Uri.base;
  final isLocalWeb =
      (base.scheme == 'http' || base.scheme == 'https') &&
      (base.host == 'localhost' || base.host == '127.0.0.1');
  if (isLocalWeb) {
    return base.replace(path: '/', query: null, fragment: '/invite/$token');
  }
  return Uri.https('pawket.app', '/invite/$token');
}
