import '../../../core/network/api_models.dart';

class PostAuthorDto {
  const PostAuthorDto({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  factory PostAuthorDto.fromJson(JsonMap json) => PostAuthorDto(
    id: json['id'] as String,
    displayName: json['displayName'] as String? ?? 'Pawket member',
    avatarUrl: json['avatarUrl'] as String?,
  );

  final String id;
  final String displayName;
  final String? avatarUrl;
}

class PostMediaDto {
  const PostMediaDto({
    required this.id,
    required this.url,
    required this.mediaType,
    this.width,
    this.height,
    this.thumbnailUrl,
  });

  factory PostMediaDto.fromJson(JsonMap json, {Uri? baseUri}) => PostMediaDto(
    id: json['id'] as String,
    url: _resolveUri(json['url'] as String, baseUri),
    thumbnailUrl: switch (json['thumbnailUrl']) {
      final String value => _resolveUri(value, baseUri),
      _ => null,
    },
    mediaType:
        json['type'] as String? ?? json['mediaType'] as String? ?? 'IMAGE',
    width: (json['width'] as num?)?.toInt(),
    height: (json['height'] as num?)?.toInt(),
  );

  final String id;
  final Uri url;
  final Uri? thumbnailUrl;
  final String mediaType;
  final int? width;
  final int? height;
}

class ReactionSummaryDto {
  const ReactionSummaryDto({required this.counts, this.currentUserReaction});

  factory ReactionSummaryDto.fromJson(JsonMap json) {
    final rawCounts = json['counts'];
    return ReactionSummaryDto(
      counts: rawCounts is Map
          ? rawCounts.map(
              (key, value) => MapEntry(key.toString(), (value as num).toInt()),
            )
          : const {},
      currentUserReaction: json['currentUserReaction'] as String?,
    );
  }

  final Map<String, int> counts;
  final String? currentUserReaction;
}

class PostDto {
  const PostDto({
    required this.id,
    required this.author,
    required this.petIds,
    required this.media,
    required this.visibility,
    required this.capturedAt,
    required this.createdAt,
    required this.reactions,
    this.caption,
    this.version,
  });

  factory PostDto.fromJson(JsonMap json, {Uri? baseUri}) => PostDto(
    id: json['id'] as String,
    author: json['author'] is Map
        ? PostAuthorDto.fromJson(
            requireJsonMap(json['author'], context: 'post author'),
          )
        : PostAuthorDto(
            id: json['authorId'] as String,
            displayName:
                json['authorDisplayName'] as String? ?? 'Pawket member',
          ),
    petIds: (json['petIds'] as List? ?? const []).whereType<String>().toList(),
    media: requireJsonList(json['media'], context: 'post media')
        .map((media) => PostMediaDto.fromJson(media, baseUri: baseUri))
        .toList(growable: false),
    visibility: json['visibility'] as String? ?? 'PRIVATE',
    capturedAt: DateTime.parse(json['capturedAt'] as String).toUtc(),
    createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
    caption: json['caption'] as String?,
    reactions:
        json['reactions'] is Map &&
            (json['reactions'] as Map).containsKey('counts')
        ? ReactionSummaryDto.fromJson(
            requireJsonMap(json['reactions'], context: 'reactions'),
          )
        : ReactionSummaryDto(
            counts: (json['reactions'] as Map? ?? const {}).map(
              (key, value) => MapEntry(key.toString(), (value as num).toInt()),
            ),
            currentUserReaction: json['myReaction'] as String?,
          ),
    version: (json['version'] as num?)?.toInt(),
  );

  final String id;
  final PostAuthorDto author;
  final List<String> petIds;
  final List<PostMediaDto> media;
  final String visibility;
  final DateTime capturedAt;
  final DateTime createdAt;
  final String? caption;
  final ReactionSummaryDto reactions;
  final int? version;
}

Uri _resolveUri(String value, Uri? baseUri) {
  final uri = Uri.parse(value);
  return uri.hasScheme || baseUri == null ? uri : baseUri.resolveUri(uri);
}

class CreatePostRequest {
  const CreatePostRequest({
    required this.petIds,
    required this.mediaIds,
    required this.capturedAt,
    this.caption,
    this.visibility = 'PET_MEMBERS',
  });

  final List<String> petIds;
  final List<String> mediaIds;
  final DateTime capturedAt;
  final String? caption;
  final String visibility;

  JsonMap toJson() => {
    'petIds': petIds,
    'mediaIds': mediaIds,
    'capturedAt': capturedAt.toUtc().toIso8601String(),
    if (caption != null && caption!.trim().isNotEmpty)
      'caption': caption!.trim(),
    'visibility': visibility,
  };
}
