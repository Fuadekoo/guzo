import '../../utils/constants.dart';

/// One coin on the track.
///
/// Unlike a [Collectible], a coin means the same thing to everybody: there is
/// no per-player role to resolve, so its value is fixed at generation time.
class Coin {
  const Coin({
    required this.id,
    required this.worldZ,
    required this.lane,
    required this.height,
  });

  /// Stable identifier, unique across the run. Phase 6 refers to a coin by
  /// this id when a client tells the host what it picked up.
  final int id;

  /// Absolute distance from the start of the run, in metres.
  final double worldZ;

  final int lane;

  /// Centre height above the road. Coins in an arc rise and fall across the
  /// run, tracing the path a jump would take.
  final double height;

  double get x => GuzoWorld.laneToX(lane);
}
