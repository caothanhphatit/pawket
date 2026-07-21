import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/bootstrap/app_providers.dart';
import '../../../core/network/api_models.dart';
import '../../posts/data/post_dto.dart';

final petFeedProvider = FutureProvider.autoDispose
    .family<CursorPage<PostDto>, String>((ref, petId) async {
      final repository = ref.watch(feedRepositoryProvider);
      return _loadAllPages(
        (cursor) => repository.getFeed(petId: petId, cursor: cursor, limit: 50),
      );
    });

final petMemoriesProvider = FutureProvider.autoDispose
    .family<CursorPage<PostDto>, String>((ref, petId) async {
      final repository = ref.watch(feedRepositoryProvider);
      return _loadAllPages(
        (cursor) =>
            repository.getPetMemories(petId: petId, cursor: cursor, limit: 50),
      );
    });

Future<CursorPage<PostDto>> _loadAllPages(
  Future<CursorPage<PostDto>> Function(String? cursor) loadPage,
) async {
  const maxPages = 20;
  final items = <PostDto>[];
  String? cursor;

  for (var pageNumber = 0; pageNumber < maxPages; pageNumber++) {
    final page = await loadPage(cursor);
    items.addAll(page.items);
    if (!page.hasMore || page.nextCursor == null) {
      return CursorPage(items: items, hasMore: false);
    }
    cursor = page.nextCursor;
  }

  return CursorPage(items: items, nextCursor: cursor, hasMore: true);
}
