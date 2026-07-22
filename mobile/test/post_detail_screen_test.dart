import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawket_mobile/app/bootstrap/app_providers.dart';
import 'package:pawket_mobile/features/posts/data/post_dto.dart';
import 'package:pawket_mobile/features/posts/data/post_repository.dart';
import 'package:pawket_mobile/features/posts/presentation/post_detail_screen.dart';

void main() {
  testWidgets('edits optional caption and audience', (tester) async {
    final repository = _FakePostRepository(_post());
    await tester.pumpWidget(_app(repository));

    await tester.tap(find.byTooltip('Edit memory'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Updated walk');
    await tester.tap(find.text('Only me'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repository.lastUpdate?.caption, 'Updated walk');
    expect(repository.lastUpdate?.visibility, 'PRIVATE');
  });

  testWidgets('requires confirmation before deleting a memory', (tester) async {
    final repository = _FakePostRepository(_post());
    await tester.pumpWidget(_app(repository));

    await tester.tap(find.byTooltip('Delete memory'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this memory?'), findsOneWidget);
    expect(repository.deletedPostId, isNull);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repository.deletedPostId, 'post-1');
  });
}

Widget _app(_FakePostRepository repository) {
  return ProviderScope(
    overrides: [postRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      home: PostDetailScreen(postId: 'post-1', initialPost: repository.post),
    ),
  );
}

PostDto _post({
  String? caption = 'Sunny walk',
  String visibility = 'PET_MEMBERS',
}) {
  final now = DateTime.utc(2026, 7, 22, 8);
  return PostDto(
    id: 'post-1',
    author: const PostAuthorDto(id: 'user-1', displayName: 'An'),
    petIds: const ['pet-1'],
    media: const [],
    visibility: visibility,
    capturedAt: now,
    createdAt: now,
    caption: caption,
    reactions: const ReactionSummaryDto(counts: {}),
    version: 1,
  );
}

class _FakePostRepository implements PostRepository {
  _FakePostRepository(this.post);

  PostDto post;
  UpdatePostRequest? lastUpdate;
  String? deletedPostId;

  @override
  Future<PostDto> createPost(
    CreatePostRequest request, {
    required String idempotencyKey,
  }) async => post;

  @override
  Future<void> deletePost(String postId) async {
    deletedPostId = postId;
  }

  @override
  Future<PostDto> getPost(String postId) async => post;

  @override
  Future<PostDto> updatePost(
    String postId,
    UpdatePostRequest request, {
    required String idempotencyKey,
  }) async {
    lastUpdate = request;
    post = _post(
      caption: request.caption?.trim().isEmpty == true ? null : request.caption,
      visibility: request.visibility,
    );
    return post;
  }
}
