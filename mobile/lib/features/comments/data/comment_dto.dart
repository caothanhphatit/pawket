import '../../../core/network/api_models.dart';

class CommentAuthorDto {
  const CommentAuthorDto({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  factory CommentAuthorDto.fromJson(JsonMap json) => CommentAuthorDto(
    id: json['id'] as String? ?? '',
    displayName: json['displayName'] as String? ?? 'Pawket member',
    avatarUrl: json['avatarUrl'] as String?,
  );

  final String id;
  final String displayName;
  final String? avatarUrl;
}

class CommentDto {
  const CommentDto({
    required this.id,
    required this.postId,
    required this.author,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.canEdit,
    this.canDelete,
  });

  factory CommentDto.fromJson(JsonMap json) {
    final author = json['author'];
    return CommentDto(
      id: json['id'] as String,
      postId: json['postId'] as String,
      author: author is Map
          ? CommentAuthorDto.fromJson(author.cast<String, dynamic>())
          : CommentAuthorDto(
              id: json['authorId'] as String? ?? '',
              displayName:
                  json['displayName'] as String? ??
                  json['authorDisplayName'] as String? ??
                  'Pawket member',
              avatarUrl: json['avatarUrl'] as String?,
            ),
      body: json['body'] as String? ?? json['text'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '')?.toUtc() ??
          DateTime.parse(json['createdAt'] as String).toUtc(),
      version: (json['version'] as num?)?.toInt() ?? 0,
      canEdit: json['canEdit'] as bool?,
      canDelete: json['canDelete'] as bool?,
    );
  }

  final String id;
  final String postId;
  final CommentAuthorDto author;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final bool? canEdit;
  final bool? canDelete;

  bool canManage(String? currentUserId) {
    if (canEdit == true || canDelete == true) return true;
    if (currentUserId != null) return author.id == currentUserId;
    return false;
  }
}

class CreateCommentRequest {
  const CreateCommentRequest(this.body);
  final String body;
  JsonMap toJson() => {'body': body.trim()};
}

class UpdateCommentRequest {
  const UpdateCommentRequest({required this.body, required this.version});
  final String body;
  final int version;
  JsonMap toJson() => {'body': body.trim(), 'version': version};
}
