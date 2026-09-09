import 'dart:math' as math;

import '../../utils/constants.dart';
import 'coin.dart';
import 'collectible.dart';
import 'obstacle_kind.dart';

/// One obstacle placed on the track.
///
/// Positions are absolute world coordinates, so an obstacle means the same
/// thing regardless of where the camera is — which is what lets Phase 6 refer
/// to an obstacle by [id] across devices.
class Obstacle {
  Obstacle({
    required this.id,
    required this.kind,
    required this.worldZ,
    required this.lane,
    this.patrolLanes = 0,
    this.patrolPhase = 0,
  });

  /// Stable identifier: `chunkIndex * _idStride + slot`.
  final int id;
  final ObstacleKind kind;

  /// Absolute distance from the start of the run, in metres.
  final double worldZ;

  /// Lane the obstacle is anchored to (-1, 0 or 1).
  final int lane;

  /// How many lanes a [ObstacleKind.movingBarrier] sweeps across. Zero for
  /// every static kind.
  final int patrolLanes;

  /// Phase offset of the patrol, in radians.
  final double patrolPhase;

  ObstacleSpec get spec => ObstacleSpecs.of(kind);

  /// Sideways position in metres.
  ///
  /// Moving barriers derive their offset from the *runner's* travelled
  /// distance rather than from accumulated time. That keeps them a pure
  /// function of world state: two devices at the same distance always see the
  /// barrier in the same place, with no clock to synchronise.
  double xAt(double travelled) {
    final double base = GuzoWorld.laneToX(lane);
    if (patrolLanes == 0) return base;

    final double approach = worldZ - travelled;
    final double wave = math.sin(approach * _patrolFrequency + patrolPhase);
    final double reach = patrolLanes * GuzoWorld.laneWidth;

    if (lane == 0) {
      // A centre barrier can swing both ways and still stay on the road.
      return base + wave * reach;
    }

    // An outer barrier sweeps inward only. Remapping the wave to [0, 1] and
    // pushing it toward the centre keeps it on the road for every phase,
    // instead of letting half the cycle carry it off the edge.
    return base - lane * (0.5 + 0.5 * wave) * reach;
  }

  /// Radians of patrol per metre travelled — roughly one sweep every 12 m.
  static const double _patrolFrequency = 0.52;
}

/// A decorative item beside the road.
class SceneryItem {
  const SceneryItem({
    required this.kind,
    required this.worldZ,
    required this.x,
    required this.scale,
  });

  final SceneryKind kind;
  final double worldZ;

  /// Sideways position in metres; always outside the road edge.
  final double x;

  /// Size multiplier so a stand of trees does not look cloned.
  final double scale;
}

/// A fixed-length slice of generated track.
///
/// Chunks are the unit of streaming: whole chunks are built ahead of the
/// runner and dropped behind. Recycling at chunk granularity rather than
/// pooling individual obstacles keeps allocation to roughly one burst every
/// [GuzoWorld.chunkLength] metres — about once every four seconds — which is
/// negligible GC pressure and far simpler to reason about than a per-entity
/// pool.
class TrackChunk {
  TrackChunk({
    required this.index,
    required this.obstacles,
    required this.scenery,
    required this.collectibles,
    required this.coins,
  });

  final int index;
  final List<Obstacle> obstacles;
  final List<SceneryItem> scenery;

  /// Educational pickups, ordered by ascending distance.
  final List<Collectible> collectibles;

  /// Coins, ordered by ascending distance.
  final List<Coin> coins;

  double get startZ => index * GuzoWorld.chunkLength;
  double get endZ => startZ + GuzoWorld.chunkLength;

  /// Spacing between obstacle ids so ids never collide between chunks.
  static const int idStride = 1000;
}
