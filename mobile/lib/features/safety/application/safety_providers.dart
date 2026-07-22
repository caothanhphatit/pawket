import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/bootstrap/app_providers.dart';
import '../data/safety_repository.dart';

final safetyRepositoryProvider = Provider<SafetyRepository>(
  (ref) => RemoteSafetyRepository(ref.watch(apiClientProvider)),
);
final userProfileProvider = FutureProvider.autoDispose
    .family<UserProfileDto, String>(
      (ref, userId) =>
          ref.watch(safetyRepositoryProvider).getUserProfile(userId),
    );
final blockedUsersProvider = FutureProvider.autoDispose<List<BlockedUserDto>>(
  (ref) => ref.watch(safetyRepositoryProvider).listBlockedUsers(),
);
