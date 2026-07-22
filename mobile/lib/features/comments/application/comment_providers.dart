import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/app_providers.dart';
import '../../../core/network/api_models.dart';
import '../data/comment_dto.dart';
import '../data/comment_repository.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  return RemoteCommentRepository(ref.watch(apiClientProvider));
});

final postCommentsProvider = FutureProvider.autoDispose
    .family<CursorPage<CommentDto>, String>((ref, postId) {
      return ref.watch(commentRepositoryProvider).list(postId);
    });
