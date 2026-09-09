import 'package:flutter_test/flutter_test.dart';
import 'package:guzo/game/world/collectible.dart';
import 'package:guzo/game/world/obstacle_kind.dart';
import 'package:guzo/game/world/track_chunk.dart';
import 'package:guzo/game/world/track_manager.dart';
import 'package:guzo/game/world/world_generator.dart';
import 'package:guzo/utils/constants.dart';

/// Flattens a chunk into a comparable signature.
List<String> _signature(TrackChunk chunk) => chunk.obstacles
    .map((Obstacle o) => '${o.id}:${o.kind}:${o.worldZ}:${o.lane}')
    .toList();

void main() {
  group('WorldGenerator determinism', () {
    test('the same seed and index produce an identical chunk', () {
      final TrackChunk a = WorldGenerator(seed: 4821).generateChunk(9);
      final TrackChunk b = WorldGenerator(seed: 4821).generateChunk(9);

      expect(_signature(a), _signature(b));
      expect(a.scenery.length, b.scenery.length);
    });

    test('different seeds produce different tracks', () {
      final TrackChunk a = WorldGenerator(seed: 1).generateChunk(12);
      final TrackChunk b = WorldGenerator(seed: 2).generateChunk(12);

      expect(_signature(a), isNot(equals(_signature(b))));
    });

    test('generation order does not change a chunk', () {
      // The multiplayer case: a client that joins late generates chunk 15
      // first, and must still see exactly what the host saw.
      final WorldGenerator inOrder = WorldGenerator(seed: 777);
      for (int i = 0; i < 15; i++) {
        inOrder.generateChunk(i);
      }
      final TrackChunk sequential = inOrder.generateChunk(15);
      final TrackChunk direct = WorldGenerator(seed: 777).generateChunk(15);

      expect(_signature(sequential), _signature(direct));
    });
  });

  group('WorldGenerator fairness rules', () {
    test('the warm-up stretch has no obstacles at all', () {
      final WorldGenerator generator = WorldGenerator(seed: 3);

      for (int i = 0; i < 2; i++) {
        for (final Obstacle obstacle in generator.generateChunk(i).obstacles) {
          expect(
            obstacle.worldZ,
            greaterThanOrEqualTo(GuzoWorld.warmUpDistance),
          );
        }
      }
    });

    test('at least one lane is always open', () {
      // The single most important rule: a child must never meet a wall.
      for (int seed = 0; seed < 12; seed++) {
        final WorldGenerator generator = WorldGenerator(seed: seed);

        for (int index = 0; index < 40; index++) {
          final Map<double, Set<int>> lanesByRow = <double, Set<int>>{};
          for (final Obstacle o in generator.generateChunk(index).obstacles) {
            lanesByRow.putIfAbsent(o.worldZ, () => <int>{}).add(o.lane);
          }

          for (final MapEntry<double, Set<int>> row in lanesByRow.entries) {
            expect(
              row.value.length,
              lessThan(GuzoWorld.laneCount),
              reason: 'seed $seed row at ${row.key} m blocked every lane',
            );
          }
        }
      }
    });

    test('rows are spaced by at least the reaction time', () {
      for (int seed = 0; seed < 8; seed++) {
        final WorldGenerator generator = WorldGenerator(seed: seed);

        final List<double> rows = <double>[];
        for (int index = 0; index < 30; index++) {
          for (final Obstacle o in generator.generateChunk(index).obstacles) {
            if (!rows.contains(o.worldZ)) rows.add(o.worldZ);
          }
        }
        rows.sort();

        for (int i = 1; i < rows.length; i++) {
          final double gap = rows[i] - rows[i - 1];
          final double minimum =
              GuzoWorld.speedAt(rows[i - 1]) * GuzoWorld.minReactionSeconds;

          expect(
            gap,
            greaterThanOrEqualTo(minimum - 0.001),
            reason: 'seed $seed: only ${gap}m between rows at ${rows[i - 1]}m',
          );
        }
      }
    });

    test('obstacles stay in real lanes', () {
      final WorldGenerator generator = WorldGenerator(seed: 42);

      for (int index = 0; index < 30; index++) {
        for (final Obstacle o in generator.generateChunk(index).obstacles) {
          expect(o.lane, inInclusiveRange(-1, 1));
        }
      }
    });

    test('scenery never sits on the road', () {
      final WorldGenerator generator = WorldGenerator(seed: 11);

      for (int index = 0; index < 20; index++) {
        for (final SceneryItem item in generator.generateChunk(index).scenery) {
          expect(item.x.abs(), greaterThan(GuzoWorld.roadHalfWidth));
        }
      }
    });

    test('scenery is pre-sorted far to near for the painter', () {
      final List<SceneryItem> scenery = WorldGenerator(
        seed: 5,
      ).generateChunk(3).scenery;

      for (int i = 1; i < scenery.length; i++) {
        expect(scenery[i].worldZ, lessThanOrEqualTo(scenery[i - 1].worldZ));
      }
    });

    test('obstacle ids are unique across chunks', () {
      final WorldGenerator generator = WorldGenerator(seed: 88);
      final Set<int> ids = <int>{};
      int total = 0;

      for (int index = 0; index < 60; index++) {
        for (final Obstacle o in generator.generateChunk(index).obstacles) {
          ids.add(o.id);
          total++;
        }
      }

      expect(ids.length, total);
    });
  });

  group('TrackManager streaming', () {
    test('primes a window around the start', () {
      final TrackManager track = TrackManager(seed: 1)..prime();

      expect(track.chunkCount, greaterThan(0));
      expect(track.chunks.first.startZ, lessThanOrEqualTo(0));
    });

    test('generates ahead and drops behind as the camera advances', () {
      final TrackManager track = TrackManager(seed: 1)..prime();
      final int primedCount = track.chunkCount;

      track.ensureGenerated(GuzoWorld.chunkLength * 20);

      // Memory stays flat no matter how far the child runs.
      expect(track.chunkCount, primedCount);
      expect(
        track.chunks.first.index,
        greaterThanOrEqualTo(20 - GuzoWorld.chunksBehind),
      );
      expect(track.chunks.last.index, 20 + GuzoWorld.chunksAhead);
    });

    test('chunks stay ordered by ascending distance', () {
      final TrackManager track = TrackManager(seed: 2)..prime();

      for (double z = 0; z < 800; z += 37) {
        track.ensureGenerated(z);
        final List<TrackChunk> chunks = track.chunks;
        for (int i = 1; i < chunks.length; i++) {
          expect(chunks[i].index, chunks[i - 1].index + 1);
        }
      }
    });

    test('obstaclesNear only returns obstacles inside the window', () {
      final TrackManager track = TrackManager(seed: 9)..prime();
      track.ensureGenerated(400);

      final List<Obstacle> near = track
          .obstaclesNear(400, 3)
          .toList(growable: false);

      for (final Obstacle o in near) {
        expect((o.worldZ - 400).abs(), lessThanOrEqualTo(3));
      }
    });
  });

  group('Collectible generation', () {
    test('the same seed and index produce identical collectibles', () {
      List<String> signature(TrackChunk chunk) => <String>[
        for (final Collectible c in chunk.collectibles)
          "${c.id}:${c.role}:${c.worldZ}:${c.lane}",
      ];

      expect(
        signature(WorldGenerator(seed: 909).generateChunk(4)),
        signature(WorldGenerator(seed: 909).generateChunk(4)),
      );
    });

    test('generation order does not change them', () {
      final WorldGenerator inOrder = WorldGenerator(seed: 55);
      for (int i = 0; i < 6; i++) {
        inOrder.generateChunk(i);
      }

      expect(
        inOrder.generateChunk(6).collectibles.map((Collectible c) => c.id),
        WorldGenerator(
          seed: 55,
        ).generateChunk(6).collectibles.map((Collectible c) => c.id),
      );
    });

    test('pickups appear, and keep appearing well into a run', () {
      final WorldGenerator generator = WorldGenerator(seed: 3);

      for (int index = 0; index < 12; index++) {
        expect(
          generator.generateChunk(index).collectibles,
          isNotEmpty,
          reason: 'chunk $index had nothing to collect',
        );
      }
    });

    test('a group never asks a child to read and dodge at once', () {
      // The clearance rule: no pickup lands near an obstacle row.
      for (int seed = 0; seed < 8; seed++) {
        final WorldGenerator generator = WorldGenerator(seed: seed);

        for (int index = 0; index < 20; index++) {
          final TrackChunk chunk = generator.generateChunk(index);

          for (final Collectible collectible in chunk.collectibles) {
            for (final Obstacle obstacle in chunk.obstacles) {
              expect(
                (collectible.worldZ - obstacle.worldZ).abs(),
                greaterThanOrEqualTo(GuzoCollectibles.obstacleClearance),
                reason:
                    'seed $seed: pickup at ${collectible.worldZ} m sits on '
                    'an obstacle at ${obstacle.worldZ} m',
              );
            }
          }
        }
      }
    });

    test('a group holds at most one target, so progress stays paced', () {
      for (int seed = 0; seed < 8; seed++) {
        final WorldGenerator generator = WorldGenerator(seed: seed);

        for (int index = 0; index < 20; index++) {
          final Map<int, int> targetsPerGroup = <int, int>{};

          for (final Collectible c
              in generator.generateChunk(index).collectibles) {
            if (c.role != CollectibleRole.target) continue;
            // Ids are `group * 10 + slot`, so the group is the id over ten.
            targetsPerGroup.update(
              c.id ~/ 10,
              (int n) => n + 1,
              ifAbsent: () => 1,
            );
          }

          for (final int count in targetsPerGroup.values) {
            expect(
              count,
              lessThanOrEqualTo(GuzoCollectibles.maxTargetsPerGroup),
            );
          }
        }
      }
    });

    test('a group sits in one lane at one height', () {
      final WorldGenerator generator = WorldGenerator(seed: 12);

      for (int index = 0; index < 15; index++) {
        final Map<int, Set<int>> lanes = <int, Set<int>>{};
        final Map<int, Set<double>> heights = <int, Set<double>>{};

        for (final Collectible c
            in generator.generateChunk(index).collectibles) {
          lanes.putIfAbsent(c.id ~/ 10, () => <int>{}).add(c.lane);
          heights.putIfAbsent(c.id ~/ 10, () => <double>{}).add(c.height);
        }

        for (final Set<int> group in lanes.values) {
          expect(group.length, 1);
        }
        for (final Set<double> group in heights.values) {
          expect(group.length, 1);
        }
      }
    });

    test('collectibles stay in real lanes and at reachable heights', () {
      final WorldGenerator generator = WorldGenerator(seed: 77);

      for (int index = 0; index < 20; index++) {
        for (final Collectible c
            in generator.generateChunk(index).collectibles) {
          expect(c.lane, inInclusiveRange(-1, 1));
          expect(
            c.height,
            anyOf(GuzoCollectibles.lowHeight, GuzoCollectibles.highHeight),
          );
        }
      }
    });

    test('nothing is placed before the settling-in distance', () {
      final WorldGenerator generator = WorldGenerator(seed: 4);

      for (final Collectible c in generator.generateChunk(0).collectibles) {
        expect(c.worldZ, greaterThanOrEqualTo(GuzoCollectibles.startDistance));
      }
    });

    test('ids are unique across a long run', () {
      final WorldGenerator generator = WorldGenerator(seed: 2024);
      final Set<int> ids = <int>{};
      int total = 0;

      for (int index = 0; index < 40; index++) {
        for (final Collectible c
            in generator.generateChunk(index).collectibles) {
          ids.add(c.id);
          total++;
        }
      }

      expect(ids.length, total);
    });

    test('collectibles are ordered by distance for the render merge', () {
      final WorldGenerator generator = WorldGenerator(seed: 6);

      for (int index = 0; index < 15; index++) {
        final List<Collectible> items = generator
            .generateChunk(index)
            .collectibles;
        for (int i = 1; i < items.length; i++) {
          expect(items[i].worldZ, greaterThanOrEqualTo(items[i - 1].worldZ));
        }
      }
    });

    test('a full alphabet is winnable in a sensible distance', () {
      // Pacing sanity: enough targets appear that a 26-item race is a couple
      // of minutes, not twenty.
      final WorldGenerator generator = WorldGenerator(seed: 1);
      int targets = 0;
      const int chunks = 10;

      for (int index = 0; index < chunks; index++) {
        targets += generator
            .generateChunk(index)
            .collectibles
            .where((Collectible c) => c.role == CollectibleRole.target)
            .length;
      }

      final double metres = chunks * GuzoWorld.chunkLength;
      final double metresPerTarget = metres / targets;

      expect(
        metresPerTarget,
        greaterThan(15),
        reason: 'targets so dense the sequence trivialises',
      );
      expect(
        metresPerTarget,
        lessThan(90),
        reason: 'targets so sparse a 26-item race would drag',
      );
    });
  });

  group('Obstacle geometry', () {
    test('every obstacle leaves a clean escape into the next lane', () {
      // Sizing invariant: dodging sideways must always work.
      for (final ObstacleKind kind in ObstacleKind.values) {
        final ObstacleSpec spec = ObstacleSpecs.of(kind);
        expect(
          spec.halfWidth + GuzoWorld.playerHalfWidth,
          lessThan(GuzoWorld.laneWidth),
          reason: '$kind is too wide to dodge',
        );
      }
    });

    test('the barrier is genuinely unjumpable and the rock is jumpable', () {
      expect(ObstacleSpecs.of(ObstacleKind.barrier).clearableByJump, isFalse);
      expect(ObstacleSpecs.of(ObstacleKind.rock).clearableByJump, isTrue);
      expect(ObstacleSpecs.of(ObstacleKind.log).clearableByJump, isTrue);
    });

    test('only the hurdle can be slid under', () {
      expect(ObstacleSpecs.of(ObstacleKind.hurdle).clearableBySlide, isTrue);
      expect(ObstacleSpecs.of(ObstacleKind.rock).clearableBySlide, isFalse);
      expect(ObstacleSpecs.of(ObstacleKind.barrier).clearableBySlide, isFalse);
    });

    test('a moving barrier stays on the road across a full sweep', () {
      for (final int lane in <int>[-1, 0, 1]) {
        for (final double phase in <double>[0, 1.1, 2.4, 4.7]) {
          final Obstacle moving = Obstacle(
            id: 1,
            kind: ObstacleKind.movingBarrier,
            worldZ: 100,
            lane: lane,
            patrolLanes: 1,
            patrolPhase: phase,
          );
          final double halfWidth = moving.spec.halfWidth;

          for (double travelled = 0; travelled < 100; travelled += 0.25) {
            expect(
              moving.xAt(travelled).abs() + halfWidth,
              lessThanOrEqualTo(GuzoWorld.roadHalfWidth),
              reason: 'lane $lane phase $phase swept off the road',
            );
          }
        }
      }
    });

    test('a moving barrier always leaves a reachable lane', () {
      // It sweeps at most one lane, so a runner two lanes away is always safe.
      final Obstacle moving = Obstacle(
        id: 1,
        kind: ObstacleKind.movingBarrier,
        worldZ: 100,
        lane: 1,
        patrolLanes: 1,
        patrolPhase: 0.7,
      );

      for (double travelled = 0; travelled < 100; travelled += 0.25) {
        final double gap = (moving.xAt(travelled) - GuzoWorld.laneToX(-1))
            .abs();
        expect(
          gap,
          greaterThan(moving.spec.halfWidth + GuzoWorld.playerHalfWidth),
        );
      }
    });

    test('a static obstacle never moves', () {
      final Obstacle rock = Obstacle(
        id: 2,
        kind: ObstacleKind.rock,
        worldZ: 80,
        lane: -1,
      );

      expect(rock.xAt(0), GuzoWorld.laneToX(-1));
      expect(rock.xAt(75), GuzoWorld.laneToX(-1));
    });
  });
}
