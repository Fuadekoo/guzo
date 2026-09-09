import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../../utils/constants.dart';
import '../camera/perspective_camera.dart';

/// Draws the ground plane: grass, the road surface, its alternating bands,
/// the verges and the dashed lane markings.
///
/// The road is drawn as one trapezoid first and detailed on top, rather than
/// as a stack of depth slices. That guarantees there is never a seam or a gap
/// near the horizon where slices become sub-pixel thin.
///
/// Nothing here allocates per frame: paints and the scratch [Path] are fields,
/// and quads are filled from raw doubles instead of [Offset] objects.
class RoadPainter {
  final Paint _grassPaint = Paint();
  final Paint _roadPaint = Paint()..color = GuzoColors.road;
  final Paint _bandPaint = Paint()..color = GuzoColors.roadBand;
  final Paint _edgePaint = Paint()..color = GuzoColors.roadEdge;
  final Paint _dashPaint = Paint()..color = GuzoColors.laneDash;

  final Path _quad = Path();

  Rect _groundRect = Rect.zero;

  /// Width of the darker strip running along each road edge, in metres.
  static const double _edgeWidth = 0.25;

  /// Lane markings: 2 m of dash followed by 2 m of gap.
  static const double _dashLength = 2.0;
  static const double _dashPeriod = 4.0;
  static const double _dashHalfWidth = 0.06;

  void resize(Vector2 size, PerspectiveCamera camera) {
    if (size.x <= 0 || size.y <= 0) return;

    _groundRect = Rect.fromLTRB(0, camera.horizonY, size.x, size.y);
    // Distant grass is hazier and lighter, which reinforces the depth cue the
    // perspective is already giving.
    _grassPaint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[GuzoColors.grassFar, GuzoColors.grass],
    ).createShader(_groundRect);
  }

  void paint(Canvas canvas, PerspectiveCamera camera) {
    if (!camera.isReady) return;

    canvas.drawRect(_groundRect, _grassPaint);
    _paintSurface(canvas, camera, GuzoWorld.roadHalfWidth, _roadPaint);
    _paintBands(canvas, camera);
    _paintEdges(canvas, camera);
    _paintLaneDashes(canvas, camera);
  }

  /// Fills a full-depth strip of road of the given half width.
  void _paintSurface(
    Canvas canvas,
    PerspectiveCamera camera,
    double halfWidth,
    Paint paint,
  ) {
    const double near = GuzoWorld.nearPlane;
    const double far = GuzoWorld.farPlane;

    _fillQuad(
      canvas,
      paint,
      camera.screenX(-halfWidth, near),
      camera.groundY(near),
      camera.screenX(halfWidth, near),
      camera.groundY(near),
      camera.screenX(halfWidth, far),
      camera.groundY(far),
      camera.screenX(-halfWidth, far),
      camera.groundY(far),
    );
  }

  /// Alternating cross-bands that make the forward motion readable.
  void _paintBands(Canvas canvas, PerspectiveCamera camera) {
    const double length = GuzoVisuals.roadBandLength;
    const double halfWidth = GuzoWorld.roadHalfWidth;

    // Anchored to the absolute world grid, so bands slide past the camera
    // rather than being redrawn from the near plane every frame.
    int index = ((camera.travelled + GuzoWorld.nearPlane) / length).floor();

    while (true) {
      final double bandStart = index * length - camera.travelled;
      if (bandStart >= GuzoWorld.farPlane) break;

      final double near = math.max(bandStart, GuzoWorld.nearPlane);
      final double far = math.min(bandStart + length, GuzoWorld.farPlane);
      index++;
      if (far <= near) continue;
      if (index.isEven) continue;

      final double yNear = camera.groundY(near);
      final double yFar = camera.groundY(far);
      // Stop once bands are thinner than a pixel; the base road already
      // covers everything beyond this point.
      if (yNear - yFar < GuzoVisuals.minBandPixels) break;

      _fillQuad(
        canvas,
        _bandPaint,
        camera.screenX(-halfWidth, near),
        yNear,
        camera.screenX(halfWidth, near),
        yNear,
        camera.screenX(halfWidth, far),
        yFar,
        camera.screenX(-halfWidth, far),
        yFar,
      );
    }
  }

  void _paintEdges(Canvas canvas, PerspectiveCamera camera) {
    const double near = GuzoWorld.nearPlane;
    const double far = GuzoWorld.farPlane;
    const double outer = GuzoWorld.roadHalfWidth;
    const double inner = GuzoWorld.roadHalfWidth - _edgeWidth;

    for (final double sign in const <double>[-1, 1]) {
      _fillQuad(
        canvas,
        _edgePaint,
        camera.screenX(sign * inner, near),
        camera.groundY(near),
        camera.screenX(sign * outer, near),
        camera.groundY(near),
        camera.screenX(sign * outer, far),
        camera.groundY(far),
        camera.screenX(sign * inner, far),
        camera.groundY(far),
      );
    }
  }

  void _paintLaneDashes(Canvas canvas, PerspectiveCamera camera) {
    const double laneEdge = GuzoWorld.laneWidth / 2;

    int index = ((camera.travelled + GuzoWorld.nearPlane) / _dashPeriod)
        .floor();

    while (true) {
      final double dashStart = index * _dashPeriod - camera.travelled;
      if (dashStart >= GuzoWorld.farPlane) break;
      index++;

      final double near = math.max(dashStart, GuzoWorld.nearPlane);
      final double far = math.min(dashStart + _dashLength, GuzoWorld.farPlane);
      if (far <= near) continue;

      final double yNear = camera.groundY(near);
      final double yFar = camera.groundY(far);
      if (yNear - yFar < GuzoVisuals.minBandPixels) break;

      for (final double sign in const <double>[-1, 1]) {
        final double centre = sign * laneEdge;
        _fillQuad(
          canvas,
          _dashPaint,
          camera.screenX(centre - _dashHalfWidth, near),
          yNear,
          camera.screenX(centre + _dashHalfWidth, near),
          yNear,
          camera.screenX(centre + _dashHalfWidth, far),
          yFar,
          camera.screenX(centre - _dashHalfWidth, far),
          yFar,
        );
      }
    }
  }

  void _fillQuad(
    Canvas canvas,
    Paint paint,
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
    double x4,
    double y4,
  ) {
    _quad
      ..reset()
      ..moveTo(x1, y1)
      ..lineTo(x2, y2)
      ..lineTo(x3, y3)
      ..lineTo(x4, y4)
      ..close();
    canvas.drawPath(_quad, paint);
  }
}
