import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

enum PawketMotion { none, fromLeft, fromRight, fromTop, fromBottom }

abstract final class PawketNavigation {
  static void go(BuildContext context, String destination) {
    final current = GoRouterState.of(context).uri.path;
    context.go(destination, extra: motionFor(current, destination));
  }

  static PawketMotion motionFor(String current, String destination) {
    if (current == '/camera' && destination == '/home') {
      return PawketMotion.fromBottom;
    }
    if (current == '/home' && destination == '/camera') {
      return PawketMotion.fromTop;
    }

    final currentTab = _tabIndex(current);
    final destinationTab = _tabIndex(destination);
    if (currentTab != null && destinationTab != null) {
      if (destinationTab < currentTab) return PawketMotion.fromLeft;
      if (destinationTab > currentTab) return PawketMotion.fromRight;
    }

    return switch (destination) {
      '/feed' => PawketMotion.fromLeft,
      '/profile' => PawketMotion.fromRight,
      '/home' => PawketMotion.fromBottom,
      _ => PawketMotion.none,
    };
  }

  static int? _tabIndex(String path) => switch (path) {
    '/feed' => 0,
    '/camera' || '/home' => 1,
    '/profile' => 2,
    _ => null,
  };
}
