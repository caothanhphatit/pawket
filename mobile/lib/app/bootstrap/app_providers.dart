import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../features/feed/data/feed_repository.dart';
import '../../features/media/data/media_repository.dart';
import '../../features/pets/data/pet_repository.dart';
import '../../features/posts/data/post_repository.dart';

final apiConfigProvider = Provider<ApiConfig>((ref) {
  return ApiConfig.fromEnvironment();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(config: ref.watch(apiConfigProvider));
});

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return RemotePetRepository(ref.watch(apiClientProvider));
});

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return RemoteFeedRepository(ref.watch(apiClientProvider));
});

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return RemoteMediaRepository(ref.watch(apiClientProvider));
});

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return RemotePostRepository(ref.watch(apiClientProvider));
});
