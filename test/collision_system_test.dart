import 'package:flutter_test/flutter_test.dart';
import 'package:guzo/game/player/player_controller.dart';
import 'package:guzo/game/systems/collision_system.dart';
import 'package:guzo/game/world/obstacle_kind.dart';
import 'package:guzo/game/world/track_chunk.dart';
import 'package:guzo/utils/constants.dart';

/// The runner's absolute world position used throughout these tests.
const double _playerZ = 100.0;

Obstacle _obstacle(ObstacleKind kind, {int lane = 0, int id = 1}) =>
    Obstacle(id: id, kind: kind, worldZ: _playerZ, lane: lane);

/// Runs the controller forward so timed states (slide, jump) settle.
void _advance(PlayerController player, double seconds) {
  const double step = 1 / 60;
  for (double t = 0; t < seconds; t += step) {
    player.update(step, 0);
  }
}

void main() {
  late CollisionSystem collisions;
  late PlayerController player;

  setUp(() {
    collisions = CollisionSystem();
    player = PlayerController();
  });

  Obstacle? check(List<Obstacle> obstacles) =>
      collisions.check(player, obstacles, _playerZ);

  group('Basic overlap', () {
    test('a rock in the runner\'s lane is a hit', () {
      expect(check(<Obstacle>[_obstacle(ObstacleKind.rock)]), isNotNull);
    });

    test('the same rock one lane over is missed', () {
      player
        ..moveLeft()
        ..update(0.5, 0);

      expect(check(<Obstacle>[_obstacle(ObstacleKind.rock)]), isNull);
    });

    test('an obstacle far ahead is not yet a hit', () {
      final Obstacle far = Obstacle(
        id: 3,
        kind: ObstacleKind.rock,
        worldZ: _playerZ + 20,
        lane: 0,
      );

      expect(check(<Obstacle>[far]), isNull);
    });

    test('an empty track never collides', () {
      expect(check(<Obstacle>[]), isNull);
    });
  });

  group('Jumping clears the low obstacles', () {
    test('a jump carries the runner over a rock', () {
      player.jump();
      _advance(player, 0.25);

      expect(player.y, greaterThan(0.85));
      expect(check(<Obstacle>[_obstacle(ObstacleKind.rock)]), isNull);
    });

    test('a jump carries the runner over a log', () {
      player.jump();
      _advance(player, 0.2);

      expect(check(<Obstacle>[_obstacle(ObstacleKind.log)]), isNull);
    });

    test('a jump does not clear a full-height barrier', () {
      player.jump();
      _advance(player, 0.375); // apex

      expect(check(<Obstacle>[_obstacle(ObstacleKind.barrier)]), isNotNull);
    });

    test('a grounded runner is caught by a rock', () {
      expect(check(<Obstacle>[_obstacle(ObstacleKind.rock)]), isNotNull);
    });
  });

  group('Sliding clears the raised obstacles', () {
    test('sliding fits under a hurdle', () {
      player.slide();

      expect(player.height, GuzoWorld.slideHeight);
      expect(check(<Obstacle>[_obstacle(ObstacleKind.hurdle)]), isNull);
    });

    test('running into a hurdle upright is a hit', () {
      expect(check(<Obstacle>[_obstacle(ObstacleKind.hurdle)]), isNotNull);
    });

    test('sliding does not save the runner from a rock', () {
      player.slide();

      expect(check(<Obstacle>[_obstacle(ObstacleKind.rock)]), isNotNull);
    });
  });

  group('Holes', () {
    test('running into a pit on foot is a hit', () {
      expect(check(<Obstacle>[_obstacle(ObstacleKind.hole)]), isNotNull);
    });

    test('an airborne runner passes over a pit', () {
      player.jump();
      _advance(player, 0.15);

      expect(check(<Obstacle>[_obstacle(ObstacleKind.hole)]), isNull);
    });

    test('sliding does not save the runner from a pit', () {
      player.slide();

      expect(check(<Obstacle>[_obstacle(ObstacleKind.hole)]), isNotNull);
    });
  });

  group('Repeat hits', () {
    test('the same obstacle cannot be hit twice', () {
      final List<Obstacle> track = <Obstacle>[_obstacle(ObstacleKind.rock)];

      expect(check(track), isNotNull);
      player.stumble();
      _advance(player, GuzoWorld.invulnerableDuration + 0.1);

      expect(check(track), isNull);
    });

    test('an invulnerable runner is not hit at all', () {
      player.stumble();
      expect(player.isInvulnerable, isTrue);

      expect(check(<Obstacle>[_obstacle(ObstacleKind.rock)]), isNull);
    });

    test('a cluster of obstacles costs only one stumble', () {
      final List<Obstacle> row = <Obstacle>[
        _obstacle(ObstacleKind.rock, lane: 0, id: 1),
        _obstacle(ObstacleKind.barrier, lane: 0, id: 2),
      ];

      expect(check(row), isNotNull);
      expect(player.stumble(), isTrue);
      // Still protected, so the second obstacle in the row is ignored.
      expect(check(row), isNull);
      expect(player.stumble(), isFalse);
    });

    test('reset clears the last-hit memory', () {
      final List<Obstacle> track = <Obstacle>[_obstacle(ObstacleKind.rock)];

      expect(check(track), isNotNull);
      collisions.reset();
      player.reset();

      expect(check(track), isNotNull);
    });
  });

  group('Moving obstacles', () {
    test('a patrolling barrier is sampled at its swept position', () {
      // Built so that at this distance the barrier has swung away from lane 1.
      final Obstacle moving = Obstacle(
        id: 9,
        kind: ObstacleKind.movingBarrier,
        worldZ: _playerZ,
        lane: 1,
        patrolLanes: 1,
        patrolPhase: 0,
      );

      player
        ..moveRight()
        ..update(0.5, 0);

      final double sweptX = moving.xAt(_playerZ - GuzoCamera.playerZ);
      final bool overlapping =
          (sweptX - player.x).abs() <
          moving.spec.halfWidth + GuzoWorld.playerHalfWidth;

      expect(check(<Obstacle>[moving]) != null, overlapping);
    });
  });
}
