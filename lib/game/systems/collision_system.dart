import '../../utils/constants.dart';
import '../player/player_controller.dart';
import '../world/obstacle_kind.dart';
import '../world/track_chunk.dart';

/// Axis-aligned box overlap between the runner and the obstacles around it.
///
/// There is no per-obstacle-kind branching here on purpose. Whether an
/// obstacle must be jumped, slid under or dodged falls straight out of the
/// boxes in [ObstacleSpecs]:
///
/// * a rock's box sits on the road, so a jump lifts the runner's feet above it;
/// * a hurdle's box starts at 1.0 m, so only the 0.8 m sliding hitbox fits;
/// * a barrier reaches 2.6 m, above the 1.4 m jump peak, so it must be dodged;
/// * a hole's box extends below the surface and barely above it, so any
///   airborne runner misses it.
class CollisionSystem {
  /// Id of the last obstacle that landed a hit. Combined with the runner's
  /// invulnerability window this stops one wide obstacle registering twice.
  int _lastHitId = -1;

  /// Depth window that should be searched around the runner, in metres.
  ///
  /// Comfortably wider than the deepest obstacle plus one frame of travel at
  /// top speed (16 m/s ÷ 60 fps ≈ 0.27 m), so nothing can tunnel through.
  /// Public because the caller does the querying — see [check].
  static const double searchWindow = 3.0;

  /// Returns the obstacle the runner is currently overlapping, or null.
  ///
  /// Takes the candidates rather than a [TrackManager] so the check has no
  /// dependency on how the world is stored. That keeps it trivially testable
  /// against a hand-built list, and in Phase 6 lets the host run this exact
  /// method over its own copy of the track to verify a client's claim.
  Obstacle? check(
    PlayerController player,
    Iterable<Obstacle> candidates,
    double playerWorldZ,
  ) {
    if (player.isInvulnerable) return null;

    final double playerBottom = player.y;
    final double playerTop = player.y + player.height;

    for (final Obstacle obstacle in candidates) {
      if (obstacle.id == _lastHitId) continue;
      if (!_overlaps(obstacle, player, playerWorldZ, playerBottom, playerTop)) {
        continue;
      }

      _lastHitId = obstacle.id;
      return obstacle;
    }

    return null;
  }

  bool _overlaps(
    Obstacle obstacle,
    PlayerController player,
    double playerWorldZ,
    double playerBottom,
    double playerTop,
  ) {
    final ObstacleSpec spec = obstacle.spec;

    // Depth first — it rejects almost everything for the least work.
    final double dz = (obstacle.worldZ - playerWorldZ).abs();
    if (dz > spec.halfDepth + GuzoWorld.playerHalfDepth) return false;

    // Sideways. Moving barriers are sampled at the runner's current distance.
    final double obstacleX = obstacle.xAt(playerWorldZ - GuzoCamera.playerZ);
    final double dx = (obstacleX - player.x).abs();
    if (dx > spec.halfWidth + GuzoWorld.playerHalfWidth) return false;

    // Vertical.
    return playerBottom < spec.top && playerTop > spec.bottom;
  }

  void reset() => _lastHitId = -1;
}
