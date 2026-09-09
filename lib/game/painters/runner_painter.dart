import 'dart:math' as math;
import 'dart:ui';

import '../../utils/constants.dart';
import '../camera/perspective_camera.dart';
import '../player/player_controller.dart';

/// Draws the runner, seen from behind.
///
/// The figure is built procedurally from the simulation state, so it always
/// agrees with the hitbox: sliding halves [PlayerController.height], which
/// flows through the projection and squashes the drawing automatically. There
/// is no separate animation clock that could drift out of sync with the rules.
///
/// Phase 7 can swap this for sprite sheets without touching the simulation.
class RunnerPainter {
  final Paint _shadow = Paint()..color = GuzoColors.ink.withValues(alpha: 0.22);
  final Paint _skin = Paint()..color = GuzoColors.runnerSkin;
  final Paint _hair = Paint()..color = GuzoColors.runnerHair;
  final Paint _shirt = Paint()..color = GuzoColors.runnerShirt;
  final Paint _shirtShade = Paint()..color = GuzoColors.runnerShirtDark;
  final Paint _shorts = Paint()..color = GuzoColors.runnerShorts;

  final Paint _limb = Paint()
    ..color = GuzoColors.runnerSkin
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  final Paint _shoe = Paint()
    ..color = GuzoColors.runnerShoe
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  /// Half-period of the invulnerability flicker, in seconds.
  static const double _flickerPeriod = 0.09;

  /// Radians of body lean per metre of pending lane change.
  static const double _leanPerMetre = 0.26;
  static const double _maxLean = 0.34;

  void paint(
    Canvas canvas,
    PerspectiveCamera camera,
    PlayerController player,
    double elapsed,
  ) {
    if (!camera.isReady) return;

    final double scale = camera.scaleAt(GuzoCamera.playerZ);
    _paintShadow(canvas, camera, player, scale);

    // Classic arcade invulnerability flicker: skipping frames costs nothing,
    // unlike an alpha layer.
    final bool hidden =
        player.isInvulnerable &&
        !player.isStumbling &&
        (elapsed / _flickerPeriod).floor().isOdd;
    if (hidden) return;

    final Offset feet = camera.project(player.x, player.y, GuzoCamera.playerZ);
    final double unit = scale; // pixels per metre at the runner's depth

    _limb.strokeWidth = 0.115 * unit;
    _shoe.strokeWidth = 0.145 * unit;

    canvas.save();
    canvas.translate(feet.dx, feet.dy);

    double lean = (player.laneOffset * _leanPerMetre).clamp(
      -_maxLean,
      _maxLean,
    );
    if (player.isStumbling) {
      lean += math.sin(elapsed * 26) * 0.13;
    }
    if (lean != 0) canvas.rotate(lean);

    switch (player.pose) {
      case PlayerPose.jumping:
        _paintTucked(canvas, unit, player.height);
      case PlayerPose.sliding:
        _paintSliding(canvas, unit, player.height);
      case PlayerPose.running:
      case PlayerPose.stumbling:
        _paintStriding(canvas, unit, player.height, player.runCycle);
    }

    canvas.restore();
  }

  void _paintShadow(
    Canvas canvas,
    PerspectiveCamera camera,
    PlayerController player,
    double scale,
  ) {
    // The shadow stays on the road and shrinks as the runner rises, which is
    // the main cue for how high a jump is.
    final double lift = (1 - player.y / 2.2).clamp(0.35, 1.0);
    _shadow.color = GuzoColors.ink.withValues(alpha: 0.22 * lift);

    canvas.drawOval(
      Rect.fromCenter(
        center: camera.project(player.x, 0, GuzoCamera.playerZ),
        width: 0.8 * lift * scale,
        height: 0.26 * lift * scale,
      ),
      _shadow,
    );
  }

  /// Normal running: alternating legs and counter-swinging arms.
  void _paintStriding(Canvas canvas, double unit, double height, double cycle) {
    final double phase = cycle * 2 * math.pi;
    final double hipY = -height * 0.45 * unit;
    final double shoulderY = -height * 0.72 * unit;

    // Back legs first so the leading leg overlaps them.
    for (final double side in const <double>[-1, 1]) {
      final double swing = math.sin(phase + (side < 0 ? 0 : math.pi));
      _drawLeg(canvas, unit, hipY, side, swing);
    }

    _drawTorso(canvas, unit, height, hipY, shoulderY);

    for (final double side in const <double>[-1, 1]) {
      // Arms swing opposite the leg on the same side.
      final double swing = math.sin(phase + (side < 0 ? math.pi : 0));
      _drawArm(canvas, unit, shoulderY, side, swing);
    }

    _drawHead(canvas, unit, height);
  }

  /// Airborne: knees tucked up, arms flung out for balance.
  void _paintTucked(Canvas canvas, double unit, double height) {
    final double hipY = -height * 0.45 * unit;
    final double shoulderY = -height * 0.72 * unit;

    for (final double side in const <double>[-1, 1]) {
      final Offset hip = Offset(side * 0.11 * unit, hipY);
      final Offset knee = Offset(side * 0.20 * unit, hipY + 0.16 * unit);
      final Offset foot = Offset(side * 0.15 * unit, hipY + 0.10 * unit);
      canvas.drawLine(hip, knee, _limb);
      canvas.drawLine(knee, foot, _limb);
      canvas.drawLine(foot, foot.translate(0, 0.02 * unit), _shoe);
    }

    _drawTorso(canvas, unit, height, hipY, shoulderY);

    for (final double side in const <double>[-1, 1]) {
      final Offset shoulder = Offset(
        side * 0.20 * unit,
        shoulderY + 0.05 * unit,
      );
      final Offset hand = Offset(side * 0.42 * unit, shoulderY - 0.14 * unit);
      canvas.drawLine(shoulder, hand, _limb);
    }

    _drawHead(canvas, unit, height);
  }

  /// Sliding: the projection has already squashed the figure, so this only
  /// has to throw the legs forward and the arms back.
  void _paintSliding(Canvas canvas, double unit, double height) {
    final double hipY = -height * 0.42 * unit;
    final double shoulderY = -height * 0.78 * unit;

    for (final double side in const <double>[-1, 1]) {
      final Offset hip = Offset(side * 0.12 * unit, hipY);
      final Offset foot = Offset(side * 0.26 * unit, hipY + 0.22 * unit);
      canvas.drawLine(hip, foot, _limb);
      canvas.drawLine(foot, foot.translate(side * 0.05 * unit, 0), _shoe);
    }

    _drawTorso(canvas, unit, height, hipY, shoulderY);

    for (final double side in const <double>[-1, 1]) {
      final Offset shoulder = Offset(
        side * 0.19 * unit,
        shoulderY + 0.04 * unit,
      );
      final Offset hand = Offset(side * 0.30 * unit, shoulderY - 0.10 * unit);
      canvas.drawLine(shoulder, hand, _limb);
    }

    _drawHead(canvas, unit, height);
  }

  void _drawLeg(
    Canvas canvas,
    double unit,
    double hipY,
    double side,
    double swing,
  ) {
    // Only the forward half of the swing lifts the foot, which is what makes
    // the gait read as running rather than skating.
    final double lift = math.max(0, swing) * 0.24 * unit;
    final double hipX = side * 0.11 * unit;
    final double footX = hipX + swing * 0.07 * unit;

    final Offset hip = Offset(hipX, hipY);
    final Offset foot = Offset(footX, -lift);
    final Offset knee = Offset(
      (hipX + footX) / 2 + side * 0.03 * unit,
      (hipY + foot.dy) / 2 + 0.03 * unit,
    );

    canvas.drawLine(hip, knee, _limb);
    canvas.drawLine(knee, foot, _limb);
    canvas.drawLine(foot, foot.translate(side * 0.04 * unit, 0), _shoe);
  }

  void _drawArm(
    Canvas canvas,
    double unit,
    double shoulderY,
    double side,
    double swing,
  ) {
    final Offset shoulder = Offset(side * 0.20 * unit, shoulderY + 0.05 * unit);
    final Offset elbow = Offset(
      side * 0.26 * unit,
      shoulderY + (0.22 + swing * 0.04) * unit,
    );
    final Offset hand = Offset(
      side * (0.22 + swing.abs() * 0.06) * unit,
      shoulderY + (0.30 - swing * 0.14) * unit,
    );

    canvas.drawLine(shoulder, elbow, _limb);
    canvas.drawLine(elbow, hand, _limb);
  }

  void _drawTorso(
    Canvas canvas,
    double unit,
    double height,
    double hipY,
    double shoulderY,
  ) {
    final double halfWidth = 0.23 * unit;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-halfWidth, shoulderY, halfWidth, hipY + 0.06 * unit),
        Radius.circular(0.10 * unit),
      ),
      _shirt,
    );
    // A shaded strip down one side gives the flat shape some volume.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          halfWidth * 0.42,
          shoulderY + 0.03 * unit,
          halfWidth,
          hipY + 0.06 * unit,
        ),
        Radius.circular(0.08 * unit),
      ),
      _shirtShade,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          -halfWidth * 0.96,
          hipY - 0.02 * unit,
          halfWidth * 0.96,
          hipY + 0.18 * unit,
        ),
        Radius.circular(0.06 * unit),
      ),
      _shorts,
    );
  }

  /// Seen from behind, the head is mostly hair with the ears just showing.
  void _drawHead(Canvas canvas, double unit, double height) {
    final double radius = 0.16 * unit;
    final Offset centre = Offset(0, -(height - 0.17) * unit);

    canvas.drawCircle(centre, radius, _hair);
    for (final double side in const <double>[-1, 1]) {
      canvas.drawCircle(
        centre.translate(side * radius * 0.92, radius * 0.18),
        radius * 0.28,
        _skin,
      );
    }
  }
}
