import 'dart:math' as math;
import 'dart:ui';

/// The four gestures GUZO understands.
enum SwipeDirection { left, right, up, down }

/// Turns a drag into at most one [SwipeDirection] per gesture.
///
/// Two decisions matter for how the controls feel to a child:
///
/// * The swipe fires **as soon as the threshold is crossed**, not when the
///   finger lifts. Waiting for the lift adds enough delay to miss an obstacle.
/// * Only one direction fires per drag. Without the latch, a long messy swipe
///   from a small hand would fire left, then up, then left again.
class SwipeRecognizer {
  SwipeRecognizer({this.threshold = 28.0});

  /// Distance in logical pixels before a drag counts as a swipe.
  final double threshold;

  double _dx = 0;
  double _dy = 0;

  /// Latched closed until [start], so a stray delta outside a gesture — or one
  /// arriving after the run is paused — can never move the runner.
  bool _fired = true;

  void start() {
    _dx = 0;
    _dy = 0;
    _fired = false;
  }

  /// Feeds one drag delta. Returns a direction exactly once per gesture.
  SwipeDirection? update(Offset delta) {
    if (_fired) return null;

    _dx += delta.dx;
    _dy += delta.dy;

    final double absX = _dx.abs();
    final double absY = _dy.abs();
    if (math.max(absX, absY) < threshold) return null;

    _fired = true;

    // The dominant axis wins, so a slightly diagonal swipe still does what the
    // child meant.
    if (absX >= absY) {
      return _dx > 0 ? SwipeDirection.right : SwipeDirection.left;
    }
    return _dy > 0 ? SwipeDirection.down : SwipeDirection.up;
  }

  void end() => _fired = true;
}
