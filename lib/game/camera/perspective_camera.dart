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
  /// Focal length before any boost widening. Set from screen size in [resize].
  double _baseFocal = 0;

  /// Multiplier applied to the focal length while boosting.
  ///
  /// A shorter focal length is a wider field of view, which is what actually
  /// makes speed feel like speed — more of the world sweeps past the edges per
  /// second. Eased rather than snapped, so the boost does not lurch.
  double boostZoom = 1.0;

  /// Focal length in pixels; a point 1 m across at 1 m depth spans this many
  /// pixels.
  double get focal => _baseFocal * boostZoom;

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
    _baseFocal = math.min(
      size.y * GuzoCamera.focalFactor,
      size.x * GuzoCamera.focalWidthCap,
    );
    horizonY = size.y * GuzoCamera.horizonFactor;
    centreX = size.x / 2;
  }

  /// Advances the camera by [distance] metres and eases it toward [targetX].
  ///
  /// [boostIntensity] is the boost ramp in `[0, 1]`; it widens the view.
  void update(
    double dt,
    double distance,
    double targetX, {
    double boostIntensity = 0,
  }) {
    travelled += distance;

    // Frame-rate independent exponential smoothing.
    final double t = 1 - math.exp(-dt / GuzoCamera.lateralSmoothing);

    final double desired = targetX * GuzoCamera.lateralFollow;
    lateralOffset += (desired - lateralOffset) * t;

    final double desiredZoom =
        1 + (GuzoEconomy.boostFocalScale - 1) * boostIntensity.clamp(0.0, 1.0);
    boostZoom += (desiredZoom - boostZoom) * t;
  }

  void reset() {
    travelled = 0;
    lateralOffset = 0;
    boostZoom = 1;
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
