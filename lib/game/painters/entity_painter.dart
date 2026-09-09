import 'dart:math' as math;
import 'dart:ui';

import '../../utils/constants.dart';
import '../camera/perspective_camera.dart';
import '../world/obstacle_kind.dart';
import '../world/track_chunk.dart';

/// Draws obstacles and roadside scenery as projected boxes and billboards.
///
/// Every solid object is built from two quads — a lit top face and a shaded
/// front face — which is enough to read as a 3D block from behind the runner
/// without any 3D machinery.
class EntityPainter {
  final Paint _fill = Paint();
  final Paint _shadow = Paint()..color = GuzoColors.ink.withValues(alpha: 0.16);
  final Path _quad = Path();

  /// Draws one obstacle. [travelled] is the camera's absolute distance, used
  /// to sample moving obstacles.
  void paintObstacle(
    Canvas canvas,
    PerspectiveCamera camera,
    Obstacle obstacle,
    double travelled,
  ) {
    final double z = camera.relativeZ(obstacle.worldZ);
    if (!camera.isVisible(z)) return;

    final ObstacleSpec spec = obstacle.spec;
    final double x = obstacle.xAt(travelled);

    switch (obstacle.kind) {
      case ObstacleKind.hole:
        _paintHole(canvas, camera, x, spec, z);
      case ObstacleKind.hurdle:
        _paintHurdle(canvas, camera, x, spec, z);
      case ObstacleKind.barrier:
        _paintBarrier(
          canvas,
          camera,
          x,
          spec,
          z,
          GuzoColors.barrierTop,
          GuzoColors.barrierFront,
        );
      case ObstacleKind.movingBarrier:
        _paintBarrier(
          canvas,
          camera,
          x,
          spec,
          z,
          GuzoColors.hurdleTop,
          GuzoColors.hurdleFront,
        );
      case ObstacleKind.rock:
        _paintGroundedBox(
          canvas,
          camera,
          x,
          spec,
          z,
          GuzoColors.rockTop,
          GuzoColors.rockFront,
        );
      case ObstacleKind.log:
        _paintGroundedBox(
          canvas,
          camera,
          x,
          spec,
          z,
          GuzoColors.logTop,
          GuzoColors.logFront,
        );
    }
  }

  void _paintGroundedBox(
    Canvas canvas,
    PerspectiveCamera camera,
    double x,
    ObstacleSpec spec,
    double z,
    Color top,
    Color front,
  ) {
    _contactShadow(canvas, camera, x, spec.halfWidth, z);
    _box(
      canvas,
      camera,
      x,
      spec.halfWidth,
      spec.bottom,
      spec.top,
      z,
      spec.halfDepth,
      top,
      front,
    );
  }

  void _paintBarrier(
    Canvas canvas,
    PerspectiveCamera camera,
    double x,
    ObstacleSpec spec,
    double z,
    Color top,
    Color front,
  ) {
    _contactShadow(canvas, camera, x, spec.halfWidth, z);
    _box(
      canvas,
      camera,
      x,
      spec.halfWidth,
      spec.bottom,
      spec.top,
      z,
      spec.halfDepth,
      top,
      front,
    );

    // A pale band across the middle so a full-height barrier never reads as a
    // jumpable block at a glance.
    final double mid = (spec.bottom + spec.top) / 2;
    _face(
      canvas,
      camera,
      x,
      spec.halfWidth * 0.98,
      mid - 0.18,
      mid + 0.18,
      z - spec.halfDepth,
      GuzoColors.postTop,
    );
  }

  /// A hurdle floats, so it gets legs down to the road to show the gap is
  /// deliberate and slideable.
  void _paintHurdle(
    Canvas canvas,
    PerspectiveCamera camera,
    double x,
    ObstacleSpec spec,
    double z,
  ) {
    _contactShadow(canvas, camera, x, spec.halfWidth, z);

    const double legHalfWidth = 0.08;
    for (final double sign in const <double>[-1, 1]) {
      final double legX = x + sign * (spec.halfWidth - legHalfWidth);
      _box(
        canvas,
        camera,
        legX,
        legHalfWidth,
        0,
        spec.bottom,
        z,
        spec.halfDepth,
        GuzoColors.postTop,
        GuzoColors.postFront,
      );
    }

    _box(
      canvas,
      camera,
      x,
      spec.halfWidth,
      spec.bottom,
      spec.top,
      z,
      spec.halfDepth,
      GuzoColors.hurdleTop,
      GuzoColors.hurdleFront,
    );
  }

  /// A pit is a dark quad lying flat on the road with a raised rim.
  void _paintHole(
    Canvas canvas,
    PerspectiveCamera camera,
    double x,
    ObstacleSpec spec,
    double z,
  ) {
    final double near = math.max(z - spec.halfDepth, GuzoWorld.nearPlane);
    final double far = z + spec.halfDepth;
    final double rim = spec.halfWidth + 0.12;

    _fill.color = GuzoColors.holeRim;
    _groundQuad(canvas, camera, x, rim, near, far, _fill);

    _fill.color = GuzoColors.holeFill;
    _groundQuad(
      canvas,
      camera,
      x,
      spec.halfWidth,
      near + 0.06,
      far - 0.06,
      _fill,
    );
  }

  /// Draws a decorative roadside item.
  void paintScenery(Canvas canvas, PerspectiveCamera camera, SceneryItem item) {
    final double z = camera.relativeZ(item.worldZ);
    if (!camera.isVisible(z)) return;

    switch (item.kind) {
      case SceneryKind.tree:
        _paintTree(canvas, camera, item, z);
      case SceneryKind.bush:
        _paintBillboard(
          canvas,
          camera,
          item.x,
          0.45 * item.scale,
          0.45 * item.scale,
          z,
          GuzoColors.bush,
        );
      case SceneryKind.boulder:
        _box(
          canvas,
          camera,
          item.x,
          0.55 * item.scale,
          0,
          0.7 * item.scale,
          z,
          0.5,
          GuzoColors.boulder,
          GuzoColors.rockFront,
        );
      case SceneryKind.signpost:
        _paintSignpost(canvas, camera, item, z);
    }
  }

  void _paintTree(
    Canvas canvas,
    PerspectiveCamera camera,
    SceneryItem item,
    double z,
  ) {
    final double height = 3.2 * item.scale;
    _box(
      canvas,
      camera,
      item.x,
      0.16 * item.scale,
      0,
      height * 0.55,
      z,
      0.16,
      GuzoColors.trunk,
      GuzoColors.trunk,
    );

    final double radius = 0.95 * item.scale;
    _paintBillboard(
      canvas,
      camera,
      item.x,
      height * 0.72,
      radius,
      z,
      GuzoColors.canopy,
    );
    _paintBillboard(
      canvas,
      camera,
      item.x - radius * 0.45,
      height * 0.58,
      radius * 0.7,
      z,
      GuzoColors.canopyLight,
    );
    _paintBillboard(
      canvas,
      camera,
      item.x + radius * 0.45,
      height * 0.58,
      radius * 0.7,
      z,
      GuzoColors.canopy,
    );
  }

  void _paintSignpost(
    Canvas canvas,
    PerspectiveCamera camera,
    SceneryItem item,
    double z,
  ) {
    final double height = 1.9 * item.scale;
    _box(
      canvas,
      camera,
      item.x,
      0.07,
      0,
      height,
      z,
      0.07,
      GuzoColors.postTop,
      GuzoColors.postFront,
    );
    _face(
      canvas,
      camera,
      item.x,
      0.42 * item.scale,
      height * 0.62,
      height,
      z,
      GuzoColors.primary,
    );
  }

  // --- Primitives ---------------------------------------------------------

  /// A solid block: top face plus the face turned toward the camera.
  void _box(
    Canvas canvas,
    PerspectiveCamera camera,
    double x,
    double halfWidth,
    double bottom,
    double top,
    double z,
    double halfDepth,
    Color topColor,
    Color frontColor,
  ) {
    final double near = math.max(z - halfDepth, GuzoWorld.nearPlane);
    final double far = math.max(z + halfDepth, near + 0.01);

    // Top face first: it is further away, so the near face paints over it.
    _fill.color = topColor;
    _fillQuad(
      canvas,
      _fill,
      camera.screenX(x - halfWidth, near),
      camera.project(0, top, near).dy,
      camera.screenX(x + halfWidth, near),
      camera.project(0, top, near).dy,
      camera.screenX(x + halfWidth, far),
      camera.project(0, top, far).dy,
      camera.screenX(x - halfWidth, far),
      camera.project(0, top, far).dy,
    );

    _face(canvas, camera, x, halfWidth, bottom, top, near, frontColor);
  }

  /// A flat, camera-facing rectangle at depth [z].
  void _face(
    Canvas canvas,
    PerspectiveCamera camera,
    double x,
    double halfWidth,
    double bottom,
    double top,
    double z,
    Color color,
  ) {
    final double depth = math.max(z, GuzoWorld.nearPlane);
    final double left = camera.screenX(x - halfWidth, depth);
    final double right = camera.screenX(x + halfWidth, depth);
    final double yTop = camera.project(0, top, depth).dy;
    final double yBottom = camera.project(0, bottom, depth).dy;

    _fill.color = color;
    canvas.drawRect(Rect.fromLTRB(left, yTop, right, yBottom), _fill);
  }

  /// A circle standing upright in the world, sized by depth.
  void _paintBillboard(
    Canvas canvas,
    PerspectiveCamera camera,
    double x,
    double y,
    double radius,
    double z,
    Color color,
  ) {
    final double depth = math.max(z, GuzoWorld.nearPlane);
    _fill.color = color;
    canvas.drawCircle(
      camera.project(x, y, depth),
      radius * camera.scaleAt(depth),
      _fill,
    );
  }

  /// A quad lying flat on the road surface.
  void _groundQuad(
    Canvas canvas,
    PerspectiveCamera camera,
    double x,
    double halfWidth,
    double near,
    double far,
    Paint paint,
  ) {
    _fillQuad(
      canvas,
      paint,
      camera.screenX(x - halfWidth, near),
      camera.groundY(near),
      camera.screenX(x + halfWidth, near),
      camera.groundY(near),
      camera.screenX(x + halfWidth, far),
      camera.groundY(far),
      camera.screenX(x - halfWidth, far),
      camera.groundY(far),
    );
  }

  void _contactShadow(
    Canvas canvas,
    PerspectiveCamera camera,
    double x,
    double halfWidth,
    double z,
  ) {
    final double scale = camera.scaleAt(z);
    canvas.drawOval(
      Rect.fromCenter(
        center: camera.project(x, 0, z),
        width: halfWidth * 2.4 * scale,
        height: 0.28 * scale,
      ),
      _shadow,
    );
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
