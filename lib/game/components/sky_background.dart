import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../utils/constants.dart';
import '../guzo_game.dart';

/// Everything above the horizon: sky gradient, sun, drifting clouds and two
/// parallax hill layers.
///
/// The backdrop is the one part of the scene that is *not* perspective
/// projected — it is effectively at infinity, so it scrolls by a flat
/// multiplier instead. It derives its horizon from the same constant the
/// camera uses, so the two always line up without one having to be laid out
/// before the other.
class SkyBackground extends Component with HasGameReference<GuzoGame> {
  SkyBackground() : super(priority: _priority);

  static const int _priority = -100;

  /// Horizontal distance in pixels after which a hill layer repeats.
  static const double _hillPeriod = 340;
  static const int _cloudCount = 6;

  final Paint _skyPaint = Paint();
  final Paint _sunPaint = Paint()..color = GuzoColors.sun;
  final Paint _sunGlowPaint = Paint()
    ..color = GuzoColors.sun.withValues(alpha: 0.28);
  final Paint _cloudPaint = Paint()..color = GuzoColors.cloud;
  final Paint _hillFarPaint = Paint()..color = GuzoColors.hillFar;
  final Paint _hillNearPaint = Paint()..color = GuzoColors.hillNear;

  final List<_Cloud> _clouds = <_Cloud>[];

  Rect _skyRect = Rect.zero;
  Offset _sunCentre = Offset.zero;
  double _sunRadius = 0;
  double _horizonY = 0;
  Path _hillFarPath = Path();
  Path _hillNearPath = Path();
  bool _laidOut = false;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;
    _layout(size);
  }

  void _layout(Vector2 size) {
    _horizonY = size.y * GuzoCamera.horizonFactor;

    // Overshoot the horizon slightly so no seam shows between sky and ground.
    _skyRect = Rect.fromLTWH(0, 0, size.x, _horizonY + 2);
    _skyPaint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[GuzoColors.skyTop, GuzoColors.skyBottom],
    ).createShader(_skyRect);

    _sunRadius = math.min(size.x, size.y) * 0.085;
    _sunCentre = Offset(size.x * 0.8, _horizonY * 0.3);

    _hillFarPath = _buildHillPath(size.x, _horizonY * 0.19, 0.0);
    _hillNearPath = _buildHillPath(size.x, _horizonY * 0.12, 0.5);

    _seedClouds(size);
    _laidOut = true;
  }

  /// One screen-width-plus-one-period strip of rolling hills sitting on the
  /// horizon. [phase] offsets the bumps so the two layers do not line up.
  Path _buildHillPath(double width, double amplitude, double phase) {
    final Path path = Path()..moveTo(0, _horizonY);
    const double step = 16;
    final double span = width + _hillPeriod;

    for (double x = 0; x <= span; x += step) {
      final double t = (x / _hillPeriod) + phase;
      final double y =
          _horizonY - amplitude * (0.5 + 0.5 * math.sin(t * 2 * math.pi));
      path.lineTo(x, y);
    }

    return path
      ..lineTo(span, _horizonY)
      ..close();
  }

  void _seedClouds(Vector2 size) {
    _clouds.clear();
    // Fixed seed: the backdrop looks identical on every device and every run.
    final math.Random random = math.Random(7);
    for (int i = 0; i < _cloudCount; i++) {
      _clouds.add(
        _Cloud(
          x: size.x * (i / _cloudCount) + random.nextDouble() * 60,
          y: _horizonY * (0.1 + random.nextDouble() * 0.45),
          scale: 0.7 + random.nextDouble() * 0.8,
        ),
      );
    }
  }

  @override
  void render(Canvas canvas) {
    if (!_laidOut) return;

    final double travelled = game.perspective.travelled;
    // Sideways camera movement shifts the backdrop the other way, which sells
    // the lane change far better than the road alone.
    final double sway =
        -game.perspective.lateralOffset * GuzoVisuals.backdropLateralShift;

    canvas.drawRect(_skyRect, _skyPaint);
    canvas.drawCircle(_sunCentre, _sunRadius * 1.55, _sunGlowPaint);
    canvas.drawCircle(_sunCentre, _sunRadius, _sunPaint);

    _renderClouds(canvas, travelled, sway);
    _renderHills(
      canvas,
      _hillFarPath,
      _hillFarPaint,
      travelled * GuzoVisuals.hillFarParallax - sway * 0.5,
    );
    _renderHills(
      canvas,
      _hillNearPath,
      _hillNearPaint,
      travelled * GuzoVisuals.hillNearParallax - sway,
    );
  }

  void _renderClouds(Canvas canvas, double travelled, double sway) {
    final double drift = travelled * GuzoVisuals.cloudParallax;
    final double wrapWidth = game.size.x + 200;

    for (final _Cloud cloud in _clouds) {
      // Modulo wrapping keeps a cloud on screen forever without mutating it.
      final double x = ((cloud.x - drift) % wrapWidth) - 100 + sway * 0.4;
      _drawCloud(canvas, x, cloud.y, cloud.scale);
    }
  }

  void _drawCloud(Canvas canvas, double x, double y, double scale) {
    final double r = 18 * scale;
    canvas.drawCircle(Offset(x, y), r, _cloudPaint);
    canvas.drawCircle(Offset(x + r * 0.9, y - r * 0.35), r * 0.85, _cloudPaint);
    canvas.drawCircle(Offset(x + r * 1.8, y), r * 0.7, _cloudPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - r * 0.6, y, r * 3.0, r * 0.9),
        Radius.circular(r * 0.45),
      ),
      _cloudPaint,
    );
  }

  void _renderHills(Canvas canvas, Path path, Paint paint, double offset) {
    canvas.save();
    canvas.translate(-(offset % _hillPeriod), 0);
    canvas.drawPath(path, paint);
    canvas.restore();
  }
}

/// Spawn data for a single drifting cloud.
class _Cloud {
  const _Cloud({required this.x, required this.y, required this.scale});

  final double x;
  final double y;
  final double scale;
}
