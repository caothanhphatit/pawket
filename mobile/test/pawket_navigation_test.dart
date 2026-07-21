import 'package:flutter_test/flutter_test.dart';
import 'package:pawket_mobile/app/routing/pawket_navigation.dart';

void main() {
  test('camera and home use vertical motion', () {
    expect(
      PawketNavigation.motionFor('/camera', '/home'),
      PawketMotion.fromBottom,
    );
    expect(
      PawketNavigation.motionFor('/home', '/camera'),
      PawketMotion.fromTop,
    );
  });

  test('bottom tabs move toward their spatial position', () {
    expect(
      PawketNavigation.motionFor('/camera', '/feed'),
      PawketMotion.fromLeft,
    );
    expect(
      PawketNavigation.motionFor('/feed', '/camera'),
      PawketMotion.fromRight,
    );
    expect(
      PawketNavigation.motionFor('/camera', '/profile'),
      PawketMotion.fromRight,
    );
    expect(
      PawketNavigation.motionFor('/profile', '/camera'),
      PawketMotion.fromLeft,
    );
    expect(
      PawketNavigation.motionFor('/profile', '/feed'),
      PawketMotion.fromLeft,
    );
  });
}
