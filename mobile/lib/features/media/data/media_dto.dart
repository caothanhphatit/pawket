import '../../../core/network/api_models.dart';

enum MediaPurpose {
  post('POST'),
  petAvatar('PET_AVATAR'),
  userAvatar('USER_AVATAR');

  const MediaPurpose(this.wireValue);
  final String wireValue;
}

class CreateUploadIntentRequest {
  const CreateUploadIntentRequest({
    required this.fileName,
    required this.mimeType,
    required this.byteSize,
    required this.purpose,
    this.checksum,
  });

  final String fileName;
  final String mimeType;
  final int byteSize;
  final MediaPurpose purpose;
  final String? checksum;

  JsonMap toJson() => {
    'fileName': fileName,
    'mimeType': mimeType,
    'byteSize': byteSize,
    if (checksum != null) 'checksum': checksum,
  };
}

class UploadIntentDto {
  const UploadIntentDto({
    required this.mediaId,
    required this.uploadUrl,
    required this.expiresAt,
    required this.requiredHeaders,
  });

  factory UploadIntentDto.fromJson(JsonMap json) {
    final rawHeaders = json['headers'] ?? json['requiredHeaders'];
    return UploadIntentDto(
      mediaId: json['mediaId'] as String,
      uploadUrl: Uri.parse(json['uploadUrl'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String).toUtc(),
      requiredHeaders: rawHeaders is Map
          ? rawHeaders.map(
              (key, value) => MapEntry(key.toString(), value.toString()),
            )
          : const {},
    );
  }

  final String mediaId;
  final Uri uploadUrl;
  final DateTime expiresAt;
  final Map<String, String> requiredHeaders;
}

class CompletedMediaDto {
  const CompletedMediaDto({
    required this.id,
    required this.status,
    this.width,
    this.height,
  });

  factory CompletedMediaDto.fromJson(JsonMap json) => CompletedMediaDto(
    id: json['id'] as String,
    status: json['status'] as String,
    width: (json['width'] as num?)?.toInt(),
    height: (json['height'] as num?)?.toInt(),
  );

  final String id;
  final String status;
  final int? width;
  final int? height;
}
