import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pawket_mobile/features/account/presentation/account_screen.dart';
import 'package:pawket_mobile/features/feed/presentation/feed_screen.dart';
import 'package:pawket_mobile/features/home/presentation/home_screen.dart';
import 'package:pawket_mobile/features/invitations/presentation/create_invitation_screen.dart';
import 'package:pawket_mobile/features/invitations/presentation/invitation_screen.dart';
import 'package:pawket_mobile/features/memberships/presentation/members_screen.dart';
import 'package:pawket_mobile/features/pets/presentation/create_pet_screen.dart';
import 'package:pawket_mobile/features/pets/presentation/edit_pet_screen.dart';
import 'package:pawket_mobile/features/pets/presentation/pet_profile_screen.dart';
import 'package:pawket_mobile/features/posts/presentation/camera_screen.dart';
import 'package:pawket_mobile/features/posts/presentation/capture_draft.dart';
import 'package:pawket_mobile/features/posts/presentation/capture_screen.dart';
import 'package:pawket_mobile/features/posts/presentation/post_detail_screen.dart';
import 'package:pawket_mobile/features/posts/data/post_dto.dart';

import 'pawket_navigation.dart';

final appRouter = GoRouter(
  initialLocation: '/camera',
  routes: [
    GoRoute(path: '/', redirect: (_, _) => '/camera'),
    GoRoute(
      path: '/camera',
      pageBuilder: (_, state) => _motionPage(
        state: state,
        fallback: PawketMotion.none,
        child: const CameraScreen(),
      ),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (_, state) => _motionPage(
        state: state,
        fallback: PawketMotion.fromBottom,
        child: const HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/feed',
      pageBuilder: (_, state) => _motionPage(
        state: state,
        fallback: PawketMotion.fromLeft,
        child: const FeedScreen(),
      ),
    ),
    GoRoute(path: '/memories', redirect: (_, _) => '/profile'),
    GoRoute(path: '/pet', redirect: (_, _) => '/profile'),
    GoRoute(
      path: '/profile',
      pageBuilder: (_, state) => _motionPage(
        state: state,
        fallback: PawketMotion.fromRight,
        child: const PetProfileScreen(),
      ),
    ),
    GoRoute(path: '/you', builder: (_, _) => const AccountScreen()),
    GoRoute(
      path: '/compose',
      pageBuilder: (_, state) => MaterialPage(
        fullscreenDialog: true,
        child: CaptureScreen(draft: state.extra as CaptureDraft?),
      ),
    ),
    GoRoute(
      path: '/posts/:postId',
      builder: (_, state) => PostDetailScreen(
        postId: state.pathParameters['postId']!,
        initialPost: state.extra is PostDto ? state.extra! as PostDto : null,
      ),
    ),
    GoRoute(
      path: '/pets/new',
      pageBuilder: (_, _) =>
          const MaterialPage(fullscreenDialog: true, child: CreatePetScreen()),
    ),
    GoRoute(
      path: '/pets/:petId/edit',
      pageBuilder: (_, state) => MaterialPage(
        fullscreenDialog: true,
        child: EditPetScreen(petId: state.pathParameters['petId']!),
      ),
    ),
    GoRoute(
      path: '/pets/:petId/members',
      builder: (_, state) =>
          MembersScreen(petId: state.pathParameters['petId']!),
    ),
    GoRoute(
      path: '/pets/:petId/invite',
      pageBuilder: (_, state) => MaterialPage(
        fullscreenDialog: true,
        child: CreateInvitationScreen(petId: state.pathParameters['petId']!),
      ),
    ),
    GoRoute(
      path: '/invite/:token',
      builder: (_, state) =>
          InvitationScreen(token: state.pathParameters['token']!),
    ),
  ],
);

Page<void> _motionPage({
  required GoRouterState state,
  required PawketMotion fallback,
  required Widget child,
}) {
  final motion = state.extra is PawketMotion
      ? state.extra! as PawketMotion
      : fallback;
  if (motion == PawketMotion.none) {
    return NoTransitionPage<void>(key: state.pageKey, child: child);
  }

  final begin = switch (motion) {
    PawketMotion.fromLeft => const Offset(-1, 0),
    PawketMotion.fromRight => const Offset(1, 0),
    PawketMotion.fromTop => const Offset(0, -1),
    PawketMotion.fromBottom => const Offset(0, 1),
    PawketMotion.none => Offset.zero,
  };

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (_, animation, _, child) {
      final position = Tween<Offset>(
        begin: begin,
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      return SlideTransition(
        position: animation.drive(position),
        child: FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: const Interval(0, .7, curve: Curves.easeOut),
          ),
          child: child,
        ),
      );
    },
  );
}
