import '../../../core/network/api_client.dart';
import '../../../core/network/api_models.dart';

class UserProfileDto {
  const UserProfileDto({
    required this.id,
    required this.displayName,
    required this.sharedPets,
    required this.recentPosts,
    this.avatarUrl,
  });
  factory UserProfileDto.fromJson(JsonMap json, ApiClient apiClient) {
    final avatarMediaId = json['avatarMediaId'] as String?;
    return UserProfileDto(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? 'Pawket member',
      avatarUrl: avatarMediaId == null
          ? null
          : apiClient.resolveUri(
              Uri.parse('/api/v1/media/$avatarMediaId/content'),
            ),
      sharedPets: requireJsonList(
        json['sharedPets'],
        context: 'shared pets',
      ).map(SharedPetDto.fromJson).toList(),
      recentPosts: requireJsonList(
        json['recentPosts'],
        context: 'recent posts',
      ).map(RecentPostDto.fromJson).toList(),
    );
  }
  final String id;
  final String displayName;
  final Uri? avatarUrl;
  final List<SharedPetDto> sharedPets;
  final List<RecentPostDto> recentPosts;
}

class SharedPetDto {
  const SharedPetDto({required this.id, required this.name});
  factory SharedPetDto.fromJson(JsonMap json) =>
      SharedPetDto(id: json['id'] as String, name: json['name'] as String);
  final String id;
  final String name;
}

class RecentPostDto {
  const RecentPostDto({
    required this.id,
    required this.capturedAt,
    this.caption,
  });
  factory RecentPostDto.fromJson(JsonMap json) => RecentPostDto(
    id: json['id'] as String,
    caption: json['caption'] as String?,
    capturedAt: DateTime.parse(json['capturedAt'] as String).toUtc(),
  );
  final String id;
  final String? caption;
  final DateTime capturedAt;
}

class BlockedUserDto {
  const BlockedUserDto({required this.userId, required this.displayName});
  factory BlockedUserDto.fromJson(JsonMap json) => BlockedUserDto(
    userId: json['userId'] as String,
    displayName: json['displayName'] as String? ?? 'Pawket member',
  );
  final String userId;
  final String displayName;
}

abstract interface class SafetyRepository {
  Future<UserProfileDto> getUserProfile(String userId);
  Future<List<BlockedUserDto>> listBlockedUsers();
  Future<void> blockUser(String userId);
  Future<void> unblockUser(String userId);
  Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
    String? details,
  });
}

class RemoteSafetyRepository implements SafetyRepository {
  const RemoteSafetyRepository(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<UserProfileDto> getUserProfile(String userId) async {
    final response = await _apiClient.get<Object>('/users/$userId');
    return UserProfileDto.fromJson(
      requireJsonMap(unwrapData(response.data), context: 'user profile'),
      _apiClient,
    );
  }

  @override
  Future<List<BlockedUserDto>> listBlockedUsers() async {
    final response = await _apiClient.get<Object>('/blocks');
    return requireJsonList(
      unwrapData(response.data),
      context: 'blocked users',
    ).map(BlockedUserDto.fromJson).toList();
  }

  @override
  Future<void> blockUser(String userId) async {
    await _apiClient.post<void>('/blocks/$userId');
  }

  @override
  Future<void> unblockUser(String userId) async {
    await _apiClient.delete<void>('/blocks/$userId');
  }

  @override
  Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
    String? details,
  }) async {
    await _apiClient.post<Object>(
      '/reports',
      data: {
        'targetType': targetType,
        'targetId': targetId,
        'reason': reason,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
      },
    );
  }
}
