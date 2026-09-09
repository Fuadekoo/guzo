import 'dart:math' as math;
import 'dart:ui';

import '../../utils/constants.dart';
import '../camera/perspective_camera.dart';
import '../world/coin.dart';

/// Draws coins as spinning gold discs.
///
/// The spin is faked the way 2D games have always faked it: the disc is drawn
/// as an ellipse whose width follows `|cos(angle)|`, so it squashes to an edge
/// and opens out again. At the thin part a bright rim is drawn instead of the
/// face, which is what stops it looking like a disc simply shrinking.
class CoinPainter {
  final Paint _fill = Paint();
  final Paint _shadow = Paint()..color = GuzoColors.ink.withValues(alpha: 0.13);

  /// Coin radius in metres.
  static const double _radius = 0.42;

  void paint(
    Canvas canvas,
    PerspectiveCamera camera,
    Coin coin,
    double elapsed,
  ) {
    final double z = camera.relativeZ(coin.worldZ);
    if (!camera.isVisible(z)) return;

    final double scale = camera.scaleAt(z);
    final double radius = _radius * scale;
    if (radius < 2) return;

    // Each coin spins on its own phase so a run shimmers rather than flashing
    // in unison.
    final double phase = (coin.id % 16) / 16 * math.pi;
    final double angle =
        elapsed * GuzoEconomy.spinTurnsPerSecond * 2 * math.pi + phase;
    final double squash = math.cos(angle).abs();

    final Offset centre = camera.project(coin.x, coin.height, z);

    // Ground shadow, so a coin in an arc reads as being up in the air.
    canvas.drawOval(
      Rect.fromCenter(
        center: camera.project(coin.x, 0, z),
        width: 0.42 * scale,
        height: 0.14 * scale,
      ),
      _shadow,
    );

    _paintDisc(canvas, centre, radius, squash);
  }

  void _paintDisc(Canvas canvas, Offset centre, double radius, double squash) {
    // Never fully edge-on: a zero-width coin blinks out of existence.
    final double width = math.max(radius * 2 * squash, radius * 0.22);

    final Rect face = Rect.fromCenter(
      center: centre,
      width: width,
      height: radius * 2,
    );

    _fill.color = GuzoColors.coinEdge;
    canvas.drawOval(face, _fill);

    // The lit face only shows once the coin has turned far enough to have one.
    if (squash > 0.22) {
      _fill.color = GuzoColors.coinFace;
      canvas.drawOval(face.deflate(radius * 0.16), _fill);

      if (squash > 0.55) {
        _fill.color = GuzoColors.coinShine;
        canvas.drawOval(
          Rect.fromCenter(
            center: centre.translate(-width * 0.16, -radius * 0.28),
            width: width * 0.3,
            height: radius * 0.6,
          ),
          _fill,
        );
      }
    }
  }
}
