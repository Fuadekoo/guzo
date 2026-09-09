import 'dart:math' as math;

import '../../utils/constants.dart';
import '../../utils/deterministic_random.dart';
import 'collectible.dart';
import 'obstacle_kind.dart';
import 'track_chunk.dart';

/// Builds track chunks from a seed.
///
/// Two guarantees hold, and the multiplayer of Phase 6 depends on both:
///
/// 1. **Deterministic.** The same `(seed, index)` pair always produces exactly
///    the same chunk, on any device.
/// 2. **Order independent.** Each chunk derives its own random stream from the
///    seed and its index, so a client that joins late and generates chunk 12
///    first gets the same result as the host that generated chunks 0..12 in
///    order. There is no carried-over generator state.
///
/// Difficulty is a function of absolute distance, not of elapsed time, so a
/// slow player and a fast player meet the same track.
class WorldGenerator {
  WorldGenerator({required this.seed});

  /// The run's seed. In multiplayer the host picks it and broadcasts it.
  final int seed;

  /// Metres between candidate obstacle rows before spacing rules are applied.
  static const double _slotSpacing = 8.0;

  /// Scenery items generated per chunk, per side of the road. Scaled to
  /// [GuzoWorld.chunkLength] to keep roadside density constant.
  static const int _sceneryPerSide = 21;

  TrackChunk generateChunk(int index) {
    final DeterministicRandom random = DeterministicRandom(
      DeterministicRandom.deriveSeed(seed, index),
    );
    final double startZ = index * GuzoWorld.chunkLength;

    // Obstacles are laid out first; collectibles then fill the calm stretches
    // between them, so a child is never asked to read a letter and dodge a
    // barrier in the same moment.
    final List<Obstacle> obstacles = _generateObstacles(random, index, startZ);

    return TrackChunk(
      index: index,
      obstacles: obstacles,
      collectibles: _generateCollectibles(random, index, startZ, obstacles),
      scenery: _generateScenery(random, startZ),
    );
  }

  List<Obstacle> _generateObstacles(
    DeterministicRandom random,
    int index,
    double startZ,
  ) {
    final List<Obstacle> obstacles = <Obstacle>[];
    final double endZ = startZ + GuzoWorld.chunkLength;

    // Rows are anchored to absolute multiples of the slot spacing rather than
    // to a running cursor. A row therefore lands at the same world z no matter
    // which chunk boundary it happens to fall near.
    double z = (startZ / _slotSpacing).ceil() * _slotSpacing;
    int slot = 0;

    // A chunk knows nothing about its neighbours — that is what makes it
    // independently generatable, and so reproducible on a client that joins
    // late. The cost is that it cannot see how close the previous chunk's last
    // row came to the boundary. Holding the first row back by one full
    // reaction gap covers the worst case: every row in the previous chunk is
    // behind startZ, so the boundary gap is at least this wide.
    double nextAllowedZ =
        startZ + GuzoWorld.speedAt(startZ) * GuzoWorld.minReactionSeconds;

    while (z < endZ) {
      final double here = z;
      z += _slotSpacing;
      slot++;

      if (here < GuzoWorld.warmUpDistance) continue;
      if (here < nextAllowedZ) continue;

      // Gap is expressed in reaction time and converted to metres using the
      // speed the runner will actually have here, so the track never
      // out-paces a child's reflexes as the run speeds up.
      final double speed = GuzoWorld.speedAt(here);
      final double gap =
          speed *
          (GuzoWorld.minReactionSeconds +
              random.nextDouble() * GuzoWorld.maxExtraGapSeconds);
      nextAllowedZ = here + gap;

      obstacles.addAll(
        _buildRow(random, index * TrackChunk.idStride + slot, here),
      );
    }

    return obstacles;
  }

  /// Builds one row of obstacles, leaving at least one lane open.
  List<Obstacle> _buildRow(DeterministicRandom random, int baseId, double z) {
    final List<ObstacleKind> palette = _paletteFor(z);
    final int blockedLanes = _blockedLaneCount(random, z);

    // Shuffle the three lanes deterministically, then block the first N. The
    // untouched remainder is the guaranteed escape route.
    final List<int> lanes = <int>[-1, 0, 1];
    _shuffle(random, lanes);

    final List<Obstacle> row = <Obstacle>[];
    for (int i = 0; i < blockedLanes; i++) {
      final ObstacleKind kind = random.pick(palette);
      final bool moving = kind == ObstacleKind.movingBarrier;

      row.add(
        Obstacle(
          id: baseId * 10 + i,
          kind: kind,
          worldZ: z,
          lane: lanes[i],
          // A patrolling barrier anchored to an outer lane sweeps inward only,
          // so it can never wander off the road.
          patrolLanes: moving ? 1 : 0,
          patrolPhase: moving ? random.range(0, 2 * math.pi) : 0,
        ),
      );
    }
    return row;
  }

  /// How many of the three lanes this row blocks. Never all three.
  int _blockedLaneCount(DeterministicRandom random, double z) {
    if (z < GuzoWorld.singleLaneUntil) return 1;

    // Ramps from a 20% to a 55% chance of a two-lane row between 180 m and
    // 900 m, then holds.
    final double t = ((z - GuzoWorld.singleLaneUntil) / 720).clamp(0.0, 1.0);
    return random.chance(0.2 + t * 0.35) ? 2 : 1;
  }

  List<ObstacleKind> _paletteFor(double z) {
    if (z < 260) return ObstacleSpecs.easy;
    if (z < 520) return ObstacleSpecs.medium;
    return ObstacleSpecs.hard;
  }

  /// Fisher–Yates using our own generator so the result stays reproducible.
  void _shuffle(DeterministicRandom random, List<int> items) {
    for (int i = items.length - 1; i > 0; i--) {
      final int j = random.nextInt(i + 1);
      final int tmp = items[i];
      items[i] = items[j];
      items[j] = tmp;
    }
  }

  /// Places groups of educational pickups in the gaps between obstacle rows.
  ///
  /// Roles, not letters, are what get stored — see [CollectibleRole]. The
  /// generator has no idea which letter any player needs, and does not need
  /// to: it only decides *whether* a tile is the target, the next one along,
  /// or some other item.
  List<Collectible> _generateCollectibles(
    DeterministicRandom random,
    int index,
    double startZ,
    List<Obstacle> obstacles,
  ) {
    final List<Collectible> collectibles = <Collectible>[];
    final double endZ = startZ + GuzoWorld.chunkLength;

    // Groups are placed into the clear intervals *between* obstacle rows
    // rather than onto their own grid and rejected when they clash. Scanning
    // the gaps guarantees the clearance instead of hoping for it, and it keeps
    // pickup density steady even where obstacles are dense.
    final List<double> rows = _rowPositions(obstacles);
    final _GroupCursor cursor = _GroupCursor(
      baseId: index * TrackChunk.idStride,
    );

    double from = startZ;
    for (final double row in rows) {
      _fillInterval(random, collectibles, cursor, from, row);
      from = row;
    }
    _fillInterval(random, collectibles, cursor, from, endZ);

    return collectibles;
  }

  /// Distinct obstacle row positions, ascending. A two-lane row shares one z.
  List<double> _rowPositions(List<Obstacle> obstacles) {
    final List<double> rows = <double>[];
    for (final Obstacle obstacle in obstacles) {
      if (rows.isEmpty || rows.last != obstacle.worldZ) {
        rows.add(obstacle.worldZ);
      }
    }
    return rows;
  }

  /// Lays groups into one clear stretch of track, keeping the required
  /// clearance from the obstacle rows at each end.
  ///
  /// A long stretch — the opening 60 m, say — takes several groups; a short
  /// one takes none.
  void _fillInterval(
    DeterministicRandom random,
    List<Collectible> into,
    _GroupCursor cursor,
    double from,
    double to,
  ) {
    const double clearance = GuzoCollectibles.obstacleClearance;

    double z = from + clearance;
    final double limit = to - clearance;

    while (true) {
      final int size =
          GuzoCollectibles.minGroupSize +
          random.nextInt(
            GuzoCollectibles.maxGroupSize - GuzoCollectibles.minGroupSize + 1,
          );
      final double span = (size - 1) * GuzoCollectibles.itemSpacing;
      if (z + span > limit) return;

      // A moment of plain running before the first pickup, so the very first
      // thing a child meets is not a decision.
      if (z >= GuzoCollectibles.startDistance) {
        into.addAll(
          _buildGroup(random, baseId: cursor.next(), startZ: z, size: size),
        );
      }

      z +=
          span +
          random.range(
            GuzoCollectibles.minGroupGap,
            GuzoCollectibles.maxGroupGap,
          );
    }
  }

  /// Builds one line of pickups in a single lane.
  ///
  /// At most one tile in a group is the target, so a group advances a player
  /// by at most one item. That is the main pacing lever: with a group roughly
  /// every 30 m and a target in about seven of ten, a 26-letter race runs a
  /// bit over a kilometre.
  List<Collectible> _buildGroup(
    DeterministicRandom random, {
    required int baseId,
    required double startZ,
    required int size,
  }) {
    final int lane = random.nextInt(GuzoWorld.laneCount) - 1;
    final bool raised = random.chance(0.3);
    final double height = raised
        ? GuzoCollectibles.highHeight
        : GuzoCollectibles.lowHeight;

    final bool hasTarget = random.chance(GuzoCollectibles.targetGroupChance);
    final int targetSlot = hasTarget ? random.nextInt(size) : -1;

    return <Collectible>[
      for (int i = 0; i < size; i++)
        Collectible(
          id: baseId * 10 + i,
          worldZ: startZ + i * GuzoCollectibles.itemSpacing,
          lane: lane,
          height: height,
          role: i == targetSlot
              ? CollectibleRole.target
              : (random.chance(0.35)
                    ? CollectibleRole.ahead
                    : CollectibleRole.decoy),
          decoySeed: random.nextInt(1 << 16),
        ),
    ];
  }

  List<SceneryItem> _generateScenery(
    DeterministicRandom random,
    double startZ,
  ) {
    final List<SceneryItem> scenery = <SceneryItem>[];

    for (int side = 0; side < 2; side++) {
      final double direction = side == 0 ? -1 : 1;

      for (int i = 0; i < _sceneryPerSide; i++) {
        final SceneryKind kind = random.pick(_sceneryPalette);
        // Bushes hug the verge; trees and boulders stand further back.
        final double inset = kind == SceneryKind.bush
            ? random.range(0.6, 1.8)
            : random.range(1.6, 7.0);

        scenery.add(
          SceneryItem(
            kind: kind,
            worldZ: startZ + random.range(0, GuzoWorld.chunkLength),
            x: direction * (GuzoWorld.roadHalfWidth + inset),
            scale: random.range(0.75, 1.35),
          ),
        );
      }
    }

    // Painter's algorithm needs far-to-near order; sorting once at generation
    // time means the render loop never sorts.
    scenery.sort(
      (SceneryItem a, SceneryItem b) => b.worldZ.compareTo(a.worldZ),
    );
    return scenery;
  }

  static const List<SceneryKind> _sceneryPalette = <SceneryKind>[
    SceneryKind.tree,
    SceneryKind.tree,
    SceneryKind.tree,
    SceneryKind.bush,
    SceneryKind.bush,
    SceneryKind.boulder,
    SceneryKind.signpost,
  ];
}

/// Hands out group ids within one chunk.
///
/// Groups are emitted interval by interval rather than from a single loop, so
/// the counter has to be carried across those calls to keep ids unique.
class _GroupCursor {
  _GroupCursor({required this.baseId});

  final int baseId;
  int _group = 0;

  int next() => baseId + _group++;
}
