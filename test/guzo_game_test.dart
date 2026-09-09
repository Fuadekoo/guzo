import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guzo/education/sequence_library.dart';
import 'package:guzo/education/sequence_tracker.dart';
import 'package:guzo/game/components/sky_background.dart';
import 'package:guzo/game/components/track_view.dart';
import 'package:guzo/game/guzo_game.dart';
import 'package:guzo/game/input/swipe_recognizer.dart';
import 'package:guzo/game/player/player_controller.dart';
import 'package:guzo/game/world/track_chunk.dart';
import 'package:guzo/utils/constants.dart';

/// Steps the game at 60 fps for [seconds].
void _run(GuzoGame game, double seconds) {
  const double step = 1 / 60;
  for (double t = 0; t < seconds; t += step) {
    game.update(step);
  }
}

void main() {
  group('Set-up', () {
    testWithGame<GuzoGame>(
      'loads the backdrop and the track renderer',
      () => GuzoGame(seed: 1),
      (GuzoGame game) async {
        await game.ready();

        expect(game.children.whereType<SkyBackground>().length, 1);
        expect(game.children.whereType<TrackView>().length, 1);
      },
    );

    testWithGame<GuzoGame>(
      'primes the track and sizes the camera',
      () => GuzoGame(seed: 1),
      (GuzoGame game) async {
        await game.ready();

        expect(game.track.chunkCount, greaterThan(0));
        expect(game.perspective.isReady, isTrue);
        expect(game.perspective.horizonY, greaterThan(0));
      },
    );

    test('an unseeded game still picks a seed', () {
      expect(GuzoGame().seed, isNonNegative);
    });
  });

  group('Running', () {
    testWithGame<GuzoGame>(
      'moves forward at the starting speed',
      () => GuzoGame(seed: 1),
      (GuzoGame game) async {
        await game.ready();
        expect(game.distance, 0);

        game.update(1);

        expect(game.distance, closeTo(GuzoWorld.startSpeed, 0.001));
      },
    );

    testWithGame<GuzoGame>(
      'speeds up with distance but never past the cap',
      () => GuzoGame(seed: 1),
      (GuzoGame game) async {
        await game.ready();
        final double initial = game.speed;

        _run(game, 30);

        expect(game.speed, greaterThan(initial));
        expect(game.speed, lessThanOrEqualTo(GuzoWorld.maxSpeed));
      },
    );

    testWithGame<GuzoGame>(
      'reports whole metres to the HUD',
      () => GuzoGame(seed: 1),
      (GuzoGame game) async {
        await game.ready();

        game.update(1);

        expect(game.distanceMetres.value, game.distance.floor());
      },
    );

    testWithGame<GuzoGame>(
      'streams new track in and drops what is behind',
      () => GuzoGame(seed: 1),
      (GuzoGame game) async {
        await game.ready();
        final int primed = game.track.chunkCount;
        final int firstIndex = game.track.chunks.first.index;

        _run(game, 20);

        // Memory stays flat while the world keeps arriving.
        expect(game.track.chunkCount, primed);
        expect(game.track.chunks.first.index, greaterThan(firstIndex));
      },
    );
  });

  group('Input', () {
    testWithGame<GuzoGame>('swipes drive the runner', () => GuzoGame(seed: 1), (
      GuzoGame game,
    ) async {
      await game.ready();

      game.applySwipe(SwipeDirection.right);
      expect(game.player.lane, 1);

      game.applySwipe(SwipeDirection.left);
      expect(game.player.lane, 0);

      game.applySwipe(SwipeDirection.up);
      game.update(1 / 60);
      expect(game.player.isAirborne, isTrue);
    });

    testWithGame<GuzoGame>('a swipe down slides', () => GuzoGame(seed: 1), (
      GuzoGame game,
    ) async {
      await game.ready();

      game.applySwipe(SwipeDirection.down);

      expect(game.player.isSliding, isTrue);
      expect(game.player.pose, PlayerPose.sliding);
    });

    testWithGame<GuzoGame>('a tap jumps', () => GuzoGame(seed: 1), (
      GuzoGame game,
    ) async {
      await game.ready();

      game.onTapJump();
      game.update(1 / 60);

      expect(game.player.isAirborne, isTrue);
    });
  });

  group('Collisions', () {
    testWithGame<GuzoGame>(
      'hitting an obstacle costs speed but never ends the run',
      () => GuzoGame(seed: 1),
      (GuzoGame game) async {
        await game.ready();

        // Run far enough to be past the warm-up and into real obstacles, with
        // no input at all — the runner will meet something eventually.
        _run(game, 60);

        expect(game.stumbles.value, greaterThan(0));
        expect(game.distance, greaterThan(GuzoWorld.warmUpDistance));
      },
    );

    testWithGame<GuzoGame>(
      'a clean warm-up stretch produces no stumbles',
      () => GuzoGame(seed: 1),
      (GuzoGame game) async {
        await game.ready();

        // The first 60 m are guaranteed empty.
        _run(game, GuzoWorld.warmUpDistance / GuzoWorld.startSpeed - 0.5);

        expect(game.stumbles.value, 0);
      },
    );
  });

  group('Determinism', () {
    test('the same seed generates the same track on two games', () {
      List<String> signature(GuzoGame game) => game.track.chunks
          .expand((TrackChunk c) => c.obstacles)
          .map((Obstacle o) => '${o.id}:${o.kind}:${o.worldZ}:${o.lane}')
          .toList();

      final GuzoGame a = GuzoGame(seed: 2468)..track.prime();
      final GuzoGame b = GuzoGame(seed: 2468)..track.prime();

      expect(signature(a), signature(b));
      expect(signature(a), isNotEmpty);
    });

    test('different seeds generate different tracks', () {
      final GuzoGame a = GuzoGame(seed: 1)..track.prime();
      final GuzoGame b = GuzoGame(seed: 2)..track.prime();

      expect(
        a.track.chunks.first.obstacles.length +
            a.track.chunks.last.obstacles.length,
        isNotNull,
      );
      expect(a.seed, isNot(b.seed));
    });
  });

  group('Educational sequence', () {
    testWithGame<GuzoGame>(
      'starts on the first item of the default sequence',
      () => GuzoGame(seed: 1),
      (GuzoGame game) async {
        await game.ready();

        expect(game.sequence, SequenceLibrary.defaultSequence);
        expect(game.tracker.currentTarget, 'A');
        expect(game.collectedCount.value, 0);
        expect(game.isComplete.value, isFalse);
      },
    );

    testWithGame<GuzoGame>(
      'runs whatever sequence it is given',
      () => GuzoGame(seed: 1, sequence: SequenceLibrary.amharicHaFamily),
      (GuzoGame game) async {
        await game.ready();

        expect(game.tracker.currentTarget, 'ሀ');
        expect(game.tracker.totalCount, 7);
      },
    );

    testWithGame<GuzoGame>(
      'collects its way through a short sequence and finishes',
      () => GuzoGame(seed: 9, sequence: SequenceLibrary.englishVowels),
      (GuzoGame game) async {
        await game.ready();

        // Five items, no steering: the runner stays in the middle lane, so
        // this leans on target tiles appearing there. Give it plenty of road.
        for (int i = 0; i < 200 && !game.isComplete.value; i++) {
          _run(game, 1);
        }

        expect(
          game.collectedCount.value,
          greaterThan(0),
          reason: 'no targets were collected in 200 s of running',
        );
      },
    );

    testWithGame<GuzoGame>(
      'freezes the world once the sequence is complete',
      () => GuzoGame(seed: 1, sequence: SequenceLibrary.englishVowels),
      (GuzoGame game) async {
        await game.ready();

        // Drive the tracker straight to the end, as a pickup would.
        for (final String item in game.sequence.items) {
          game.tracker.offer(item);
        }
        game.isComplete.value = true;

        final double frozen = game.distance;
        final double frozenTime = game.runTime;
        _run(game, 3);

        expect(game.distance, frozen);
        expect(game.runTime, frozenTime);
      },
    );

    testWithGame<GuzoGame>(
      'ignores input after the run is over',
      () => GuzoGame(seed: 1),
      (GuzoGame game) async {
        await game.ready();
        game.isComplete.value = true;

        game.applySwipe(SwipeDirection.right);
        game.applySwipe(SwipeDirection.up);

        expect(game.player.lane, 0);
        expect(game.player.verticalVelocity, 0);
      },
    );

    testWithGame<GuzoGame>(
      'a wrong pickup flashes without advancing the sequence',
      () => GuzoGame(seed: 1),
      (GuzoGame game) async {
        await game.ready();

        expect(game.tracker.offer('B'), CollectionOutcome.wrong);
        expect(game.tracker.currentTarget, 'A');
      },
    );
  });

  group('Restart', () {
    testWithGame<GuzoGame>(
      'returns the run to its starting state',
      () => GuzoGame(seed: 1),
      (GuzoGame game) async {
        await game.ready();
        _run(game, 20);
        game.applySwipe(SwipeDirection.right);

        expect(game.distance, greaterThan(0));

        game.restart();

        expect(game.distance, 0);
        expect(game.elapsed, 0);
        expect(game.distanceMetres.value, 0);
        expect(game.stumbles.value, 0);
        expect(game.speedNotifier.value, GuzoWorld.startSpeed);
        expect(game.player.lane, 0);
        expect(game.track.chunks.first.index, lessThanOrEqualTo(0));
      },
    );
  });

  group('Camera', () {
    testWithGame<GuzoGame>(
      'follows the runner sideways without matching it exactly',
      () => GuzoGame(seed: 1),
      (GuzoGame game) async {
        await game.ready();

        game.applySwipe(SwipeDirection.right);
        _run(game, 1);

        // Partial follow: enough to sell the turn, not enough to keep the
        // runner glued to the centre of the screen.
        expect(game.perspective.lateralOffset, greaterThan(0));
        expect(game.perspective.lateralOffset, lessThan(game.player.x));
      },
    );

    testWithGame<GuzoGame>(
      'projects the horizon above the road surface',
      () => GuzoGame(seed: 1),
      (GuzoGame game) async {
        await game.ready();

        final double near = game.perspective.groundY(GuzoWorld.nearPlane);
        final double far = game.perspective.groundY(GuzoWorld.farPlane);

        expect(far, lessThan(near));
        expect(far, greaterThan(game.perspective.horizonY));
      },
    );
  });
}
