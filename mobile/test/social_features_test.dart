import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawket_mobile/core/network/api_models.dart';
import 'package:pawket_mobile/features/comments/application/comment_providers.dart';
import 'package:pawket_mobile/features/comments/data/comment_dto.dart';
import 'package:pawket_mobile/features/comments/data/comment_repository.dart';
import 'package:pawket_mobile/features/comments/presentation/comments_section.dart';
import 'package:pawket_mobile/features/notifications/data/notification_dto.dart';
import 'package:pawket_mobile/features/notifications/data/notification_repository.dart';
import 'package:pawket_mobile/features/notifications/application/notification_providers.dart';
import 'package:pawket_mobile/features/notifications/presentation/notification_badge.dart';
import 'package:pawket_mobile/features/notifications/presentation/notification_inbox_screen.dart';

void main() {
  test('comment parser supports flattened author and text aliases', () {
    final comment = CommentDto.fromJson({
      'id': 'comment-1',
      'postId': 'post-1',
      'authorId': 'user-1',
      'displayName': 'An',
      'text': 'So cute',
      'createdAt': '2026-07-22T08:00:00Z',
      'version': 2,
    });

    expect(comment.author.displayName, 'An');
    expect(comment.body, 'So cute');
    expect(comment.version, 2);
  });

  test('notification parser supports nested targets and routes', () {
    final notification = PawketNotificationDto.fromJson({
      'id': 'notification-1',
      'type': 'COMMENT_CREATED',
      'title': 'New comment',
      'body': 'An commented on a memory',
      'createdAt': '2026-07-22T08:00:00Z',
      'target': {'postId': 'post-1'},
    });

    expect(notification.isRead, isFalse);
    expect(notificationRoute(notification), '/posts/post-1');
  });

  test('comment update request includes body and optimistic version', () {
    const request = UpdateCommentRequest(body: '  Updated  ', version: 4);
    expect(request.toJson(), {'body': 'Updated', 'version': 4});
  });

  testWidgets('comments section posts and refreshes without losing input', (
    tester,
  ) async {
    final repository = _FakeCommentRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [commentRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CommentsSection(postId: 'post-1'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'First comment');
    await tester.tap(find.byTooltip('Post comment'));
    await tester.pumpAndSettle();

    expect(repository.createdBody, 'First comment');
    expect(find.text('First comment'), findsOneWidget);
    expect(repository.listCalls, greaterThanOrEqualTo(2));
  });

  testWidgets('unread badge and read-all action refresh notification state', (
    tester,
  ) async {
    final repository = _FakeNotificationRepository();
    await tester.pumpWidget(
      ProviderScope(
        key: const ValueKey('badge-scope'),
        overrides: [
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: NotificationInboxScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('New comment'), findsOneWidget);
    await tester.tap(find.text('Read all'));
    await tester.pumpAndSettle();
    expect(repository.didMarkAllRead, isTrue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unreadNotificationCountProvider.overrideWith((_) async => 3),
        ],
        child: const MaterialApp(home: Scaffold(body: NotificationBadge())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Badge), findsOneWidget);
  });
}

class _FakeCommentRepository implements CommentRepository {
  final comments = <CommentDto>[];
  String? createdBody;
  int listCalls = 0;

  @override
  Future<CommentDto> create(
    String postId,
    CreateCommentRequest request, {
    required String idempotencyKey,
  }) async {
    createdBody = request.body;
    final comment = _comment(request.body);
    comments.add(comment);
    return comment;
  }

  @override
  Future<void> delete(String commentId) async {
    comments.removeWhere((comment) => comment.id == commentId);
  }

  @override
  Future<CursorPage<CommentDto>> list(String postId) async {
    listCalls++;
    return CursorPage(items: List.of(comments), hasMore: false);
  }

  @override
  Future<CommentDto> update(
    String commentId,
    UpdateCommentRequest request, {
    required String idempotencyKey,
  }) async => _comment(request.body);
}

CommentDto _comment(String body) {
  final now = DateTime.utc(2026, 7, 22, 8);
  return CommentDto(
    id: 'comment-1',
    postId: 'post-1',
    author: const CommentAuthorDto(id: 'user-1', displayName: 'An'),
    body: body,
    createdAt: now,
    updatedAt: now,
    version: 1,
  );
}

class _FakeNotificationRepository implements NotificationRepository {
  bool didMarkAllRead = false;

  @override
  Future<CursorPage<PawketNotificationDto>> list() async => CursorPage(
    items: [
      PawketNotificationDto(
        id: 'notification-1',
        type: 'COMMENT',
        title: 'New comment',
        body: 'An commented',
        createdAt: DateTime.utc(2026, 7, 22),
      ),
    ],
    hasMore: false,
  );

  @override
  Future<void> markAllRead() async {
    didMarkAllRead = true;
  }

  @override
  Future<void> markRead(String notificationId) async {}

  @override
  Future<int> unreadCount() async => 1;
}
