import 'dart:math' as math;
import 'dart:ui';

import '../../utils/constants.dart';
import '../camera/perspective_camera.dart';
import '../player/player_controller.dart';

/// Draws the speed boost: streaks rushing past the camera and a trail behind
/// the runner.
///
/// Everything scales off one number, [BoostController.intensity], which ramps
/// in fast and out slowly. Nothing here snaps on or off — a boost that appears
/// and vanishes in a single frame reads as a glitch rather than as speed.
///
/// The streaks radiate from the vanishing point rather than falling straight
/// down the screen. That matches the direction the world is actually moving in
/// a perspective view, so they feel like the road rushing past instead of rain.
class BoostEffectPainter {
  final Paint _streak = Paint()
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final Paint _fill = Paint();

  /// Streaks drawn at full intensity.
  static const int _streakCount = 26;

  /// Ghost copies drawn behind the runner.
  static const int _trailCount = 4;

  /// Fixed layout of the streaks, so they do not jitter frame to frame.
  final List<_Streak> _streaks = List<_Streak>.generate(_streakCount, (int i) {
    final math.Random random = math.Random(4821 + i);
    return _Streak(
      angle: random.nextDouble() * 2 * math.pi,
      // Square-rooted so streaks spread evenly over the area rather than
      // bunching around the vanishing point.
      radius: math.sqrt(random.nextDouble()),
      length: 0.10 + random.nextDouble() * 0.22,
      speed: 0.7 + random.nextDouble() * 0.9,
      width: 1.4 + random.nextDouble() * 2.4,
    );
  });

  /// Draws the trail behind the runner. Called before the runner itself.
  void paintTrail(
    Canvas canvas,
    PerspectiveCamera camera,
    PlayerController player,
    double intensity,
  ) {
    if (intensity <= 0.01) return;

    for (int i = 1; i <= _trailCount; i++) {
      final double back = i * 0.55;
      // Behind the runner means closer to the camera, so each ghost is larger
      // and lower on screen — which is exactly how motion smears toward you.
      final double z = GuzoCamera.playerZ - back;
      if (z <= GuzoWorld.nearPlane) break;

      final double fade = (1 - i / (_trailCount + 1)) * intensity * 0.4;
      final double scale = camera.scaleAt(z);

      _fill.color = GuzoColors.boostTrail.withValues(alpha: fade);
      canvas.drawOval(
        Rect.fromCenter(
          center: camera.project(player.x, player.y + player.height * 0.45, z),
          width: 0.6 * scale,
          height: player.height * 0.9 * scale,
        ),
        _fill,
      );
    }
  }

  /// Draws the streaks over the world. Called after everything else.
  void paintStreaks(
    Canvas canvas,
    PerspectiveCamera camera,
    double intensity,
    double elapsed,
  ) {
    if (intensity <= 0.01) return;

    final Offset origin = Offset(camera.centreX, camera.horizonY);
    final double reach = camera.viewport.length;

    for (final _Streak streak in _streaks) {
      // Each streak cycles outward from the vanishing point and wraps.
      final double travel =
          (streak.radius + elapsed * streak.speed * (0.6 + intensity)) % 1.0;

      // Fade in near the centre and out at the edge, so nothing pops.
      final double edgeFade = math.sin(travel * math.pi);
      final double alpha = edgeFade * intensity * 0.55;
      if (alpha <= 0.01) continue;

      final double from = travel * reach;
      final double to = from + streak.length * reach * (0.4 + intensity * 0.9);

      final double dx = math.cos(streak.angle);
      final double dy = math.sin(streak.angle);

      _streak
        ..color = GuzoColors.boostStreak.withValues(alpha: alpha)
        ..strokeWidth = streak.width * (0.5 + intensity * 0.8);

      canvas.drawLine(
        origin.translate(dx * from, dy * from),
        origin.translate(dx * to, dy * to),
        _streak,
      );
    }
  }
}

/// Fixed placement of one streak.
class _Streak {
  const _Streak({
    required this.angle,
    required this.radius,
    required this.length,
    required this.speed,
    required this.width,
  });

  final double angle;
  final double radius;
  final double length;
  final double speed;
  final double width;
}
