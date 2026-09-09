import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../utils/constants.dart';

/// Projects the metre-based world onto the screen with a pinhole perspective.
///
/// GUZO is a behind-the-runner lane game, so the simulation is 3D-ish
/// (`x` = sideways, `y` = height, `z` = distance ahead) while the renderer is
/// plain 2D canvas work. This class is the only place the two meet: the
/// simulation never knows about pixels, and the painters never do maths on
/// world rules.
///
/// Coordinates:
/// * `x` — metres right of the road centre.
/// * `y` — metres above the road surface.
/// * `z` — metres ahead of the camera (**relative**, not absolute).
///
/// Absolute world positions are converted with [relativeZ].
class PerspectiveCamera {
  /// Focal length in pixels; a point 1 m across at 1 m depth spans this many
  /// pixels. Set from screen height in [resize].
  double focal = 0;

  /// Screen y of the vanishing line.
  double horizonY = 0;

  /// Screen x of the road centre.
  double centreX = 0;

  /// Screen size last given to [resize].
  Vector2 viewport = Vector2.zero();

  /// Metres travelled by the camera since the run started.
  double travelled = 0;

  /// Camera's own sideways offset in metres; eases toward the runner.
  double lateralOffset = 0;

  bool get isReady => focal > 0;

  void resize(Vector2 size) {
    if (size.x <= 0 || size.y <= 0) return;
    viewport = size.clone();
    focal = math.min(
      size.y * GuzoCamera.focalFactor,
      size.x * GuzoCamera.focalWidthCap,
    );
    horizonY = size.y * GuzoCamera.horizonFactor;
    centreX = size.x / 2;
  }

  /// Advances the camera by [distance] metres and eases it toward [targetX].
  void update(double dt, double distance, double targetX) {
    travelled += distance;

    final double desired = targetX * GuzoCamera.lateralFollow;
    // Frame-rate independent exponential smoothing.
    final double t = 1 - math.exp(-dt / GuzoCamera.lateralSmoothing);
    lateralOffset += (desired - lateralOffset) * t;
  }

  void reset() {
    travelled = 0;
    lateralOffset = 0;
  }

  /// Converts an absolute world z into a camera-relative depth.
  double relativeZ(double worldZ) => worldZ - travelled;

  /// The absolute world z the runner currently occupies.
  double get playerWorldZ => travelled + GuzoCamera.playerZ;

  /// Pixels per metre at depth [z]. Clamped at the near plane so geometry
  /// passing the camera cannot blow up to infinity.
  double scaleAt(double z) => focal / math.max(z, GuzoWorld.nearPlane);

  /// Projects a world point to the screen.
  Offset project(double x, double y, double z) {
    final double s = scaleAt(z);
    return Offset(
      centreX + (x - lateralOffset) * s,
      horizonY + (GuzoCamera.height - y) * s,
    );
  }

  /// Screen y of the road surface at depth [z].
  double groundY(double z) => horizonY + GuzoCamera.height * scaleAt(z);

  /// Screen x of world [x] at depth [z].
  double screenX(double x, double z) =>
      centreX + (x - lateralOffset) * scaleAt(z);

  /// True when [z] is inside the drawable depth range.
  bool isVisible(double z) => z > GuzoWorld.nearPlane && z < GuzoWorld.farPlane;
}
