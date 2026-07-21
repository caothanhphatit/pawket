import '../../../core/network/api_client.dart';
import '../../../core/network/api_models.dart';

class AccountDto {
  const AccountDto({
    required this.id,
    required this.displayName,
    this.avatarUrl,
  });

  factory AccountDto.fromJson(JsonMap json, {required ApiClient apiClient}) {
    final avatarMediaId = json['avatarMediaId'] as String?;
    return AccountDto(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? 'Pawket member',
      avatarUrl: avatarMediaId == null
          ? null
          : apiClient.resolveUri(
              Uri.parse('/api/v1/media/$avatarMediaId/content'),
            ),
    );
  }

  final String id;
  final String displayName;
  final Uri? avatarUrl;
}

abstract interface class AccountRepository {
  Future<AccountDto> getCurrent();
}

class RemoteAccountRepository implements AccountRepository {
  const RemoteAccountRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AccountDto> getCurrent() async {
    final response = await _apiClient.get<Object>('/users/me');
    return AccountDto.fromJson(
      requireJsonMap(unwrapData(response.data), context: 'current user'),
      apiClient: _apiClient,
    );
  }
}
