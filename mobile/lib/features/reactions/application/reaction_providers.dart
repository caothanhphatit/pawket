import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/app_providers.dart';
import '../data/reaction_repository.dart';

final reactionRepositoryProvider = Provider<ReactionRepository>((ref) {
  return RemoteReactionRepository(ref.watch(apiClientProvider));
});
