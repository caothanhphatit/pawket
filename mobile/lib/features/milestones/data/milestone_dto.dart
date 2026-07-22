import '../../../core/network/api_models.dart';

enum MilestoneType {
  birthday('BIRTHDAY'),
  homeDay('HOME_DAY'),
  firstTrip('FIRST_TRIP'),
  custom('CUSTOM');

  const MilestoneType(this.wireValue);
  final String wireValue;

  static MilestoneType fromWire(String value) =>
      MilestoneType.values.firstWhere(
        (type) => type.wireValue == value,
        orElse: () => MilestoneType.custom,
      );
}

class MilestoneDto {
  const MilestoneDto({
    required this.id,
    required this.petId,
    required this.creatorUserId,
    required this.type,
    required this.occurredOn,
    required this.createdAt,
    this.customTitle,
    this.note,
  });

  factory MilestoneDto.fromJson(JsonMap json) => MilestoneDto(
    id: json['id'] as String,
    petId: json['petId'] as String,
    creatorUserId: json['creatorUserId'] as String,
    type: MilestoneType.fromWire(json['type'] as String),
    customTitle: json['customTitle'] as String?,
    occurredOn: DateTime.parse(json['occurredOn'] as String),
    note: json['note'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
  );

  final String id;
  final String petId;
  final String creatorUserId;
  final MilestoneType type;
  final String? customTitle;
  final DateTime occurredOn;
  final String? note;
  final DateTime createdAt;

  String get title => switch (type) {
    MilestoneType.birthday => 'Birthday',
    MilestoneType.homeDay => 'Home day',
    MilestoneType.firstTrip => 'First trip',
    MilestoneType.custom => customTitle ?? 'Milestone',
  };
}

class CreateMilestoneRequest {
  const CreateMilestoneRequest({
    required this.type,
    required this.occurredOn,
    this.customTitle,
    this.note,
  });

  final MilestoneType type;
  final DateTime occurredOn;
  final String? customTitle;
  final String? note;

  JsonMap toJson() => {
    'type': type.wireValue,
    'occurredOn': _dateOnly(occurredOn),
    if (customTitle != null && customTitle!.trim().isNotEmpty)
      'customTitle': customTitle!.trim(),
    if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
  };
}

String _dateOnly(DateTime value) {
  String twoDigits(int part) => part.toString().padLeft(2, '0');
  return '${value.year}-${twoDigits(value.month)}-${twoDigits(value.day)}';
}
