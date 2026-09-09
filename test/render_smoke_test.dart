import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guzo/education/sequence_library.dart';
import 'package:guzo/game/guzo_game.dart';
import 'package:guzo/game/input/swipe_recognizer.dart';
import 'package:guzo/utils/constants.dart';

/// Renders one frame to a throwaway canvas.
///
/// The simulation tests never touch the painters, so without this the whole
/// projection and drawing layer would be untested. Driving a real [Canvas]
/// catches malformed paths, NaN coordinates and null paints — the failures
/// that would otherwise only show up on a device.
void _renderFrame(GuzoGame game) {
  final PictureRecorder recorder = PictureRecorder();
  final Canvas canvas = Canvas(recorder);
  game.render(canvas);
  recorder.endRecording().dispose();
}

void _run(GuzoGame game, double seconds) {
  const double step = 1 / 60;
  for (double t = 0; t < seconds; t += step) {
    game.update(step);
  }
}

void main() {
  group('Rendering', () {
    testWithGame<GuzoGame>('draws the opening frame', () => GuzoGame(seed: 1), (
      GuzoGame game,
    ) async {
      await game.ready();

      expect(() => _renderFrame(game), returnsNormally);
    });

    testWithGame<GuzoGame>(
      'draws every frame across a long run',
      () => GuzoGame(seed: 4821),
      (GuzoGame game) async {
        await game.ready();

        // Far enough to pass every difficulty tier, so holes, hurdles and
        // patrolling barriers all get drawn at least once.
        for (int i = 0; i < 40; i++) {
          _run(game, 2);
          expect(
            () => _renderFrame(game),
            returnsNormally,
            reason: 'failed at ${game.distance.toStringAsFixed(0)} m',
          );
        }

        expect(game.distance, greaterThan(600));
      },
    );

    testWithGame<GuzoGame>('draws each runner pose', () => GuzoGame(seed: 1), (
      GuzoGame game,
    ) async {
      await game.ready();

      game.applySwipe(SwipeDirection.up);
      _run(game, 0.2);
      expect(() => _renderFrame(game), returnsNormally);

      _run(game, 1);
      game.applySwipe(SwipeDirection.down);
      expect(() => _renderFrame(game), returnsNormally);

      game.player.stumble();
      expect(() => _renderFrame(game), returnsNormally);

      game.applySwipe(SwipeDirection.left);
      _run(game, 0.08);
      expect(() => _renderFrame(game), returnsNormally);
    });

    testWithGame<GuzoGame>(
      'survives portrait phone and extreme screen shapes',
      () => GuzoGame(seed: 1),
      (GuzoGame game) async {
        await game.ready();

        for (final Vector2 size in <Vector2>[
          Vector2(390, 844), // portrait phone, the shipped shape
          Vector2(200, 1400), // absurdly narrow: the focal-length width cap
          Vector2(1024, 768), // landscape tablet
        ]) {
          game.onGameResize(size);
          _run(game, 3);

          expect(game.perspective.focal, greaterThan(0));
          expect(
            () => _renderFrame(game),
            returnsNormally,
            reason: 'failed at $size',
          );
        }
      },
    );
  });

  group('Collectible rendering', () {
    testWithGame<GuzoGame>(
      'draws Amharic tiles without a shaping failure',
      () => GuzoGame(seed: 5, sequence: SequenceLibrary.amharicFidel),
      (GuzoGame game) async {
        await game.ready();

        // Ethiopic glyphs go through a different font path than Latin, so
        // they get their own pass. This proves the layout succeeds; whether a
        // font exists to draw them is a device question (assets/fonts/README).
        for (int i = 0; i < 12; i++) {
          _run(game, 2);
          expect(() => _renderFrame(game), returnsNormally);
        }
      },
    );

    testWithGame<GuzoGame>(
      'draws three-digit tiles, the widest a sequence can hold',
      () => GuzoGame(seed: 5, sequence: SequenceLibrary.numbersToHundred),
      (GuzoGame game) async {
        await game.ready();

        for (int i = 0; i < 12; i++) {
          _run(game, 2);
          expect(() => _renderFrame(game), returnsNormally);
        }
      },
    );

    testWithGame<GuzoGame>(
      'keeps drawing after the sequence is finished',
      () => GuzoGame(seed: 5, sequence: SequenceLibrary.englishVowels),
      (GuzoGame game) async {
        await game.ready();
        _run(game, 10);

        for (final String item in game.sequence.items) {
          game.tracker.offer(item);
        }
        game.isComplete.value = true;

        // Every tile resolves to null now, so the painter has to skip them
        // rather than trip over the empty value.
        expect(() => _renderFrame(game), returnsNormally);
      },
    );
  });

  group('Projection', () {
    testWithGame<GuzoGame>(
      'the road converges toward the horizon',
      () => GuzoGame(seed: 1),
      (GuzoGame game) async {
        await game.ready();

        final double nearHalf =
            game.perspective.screenX(GuzoWorld.roadHalfWidth, 5) -
            game.perspective.centreX;
        final double farHalf =
            game.perspective.screenX(GuzoWorld.roadHalfWidth, 80) -
            game.perspective.centreX;

        expect(nearHalf, greaterThan(farHalf));
        expect(farHalf, greaterThan(0));
      },
    );

    testWithGame<GuzoGame>(
      'a jump lifts the runner up the screen',
      () => GuzoGame(seed: 1),
      (GuzoGame game) async {
        await game.ready();

        final double grounded = game.perspective
            .project(0, 0, GuzoCamera.playerZ)
            .dy;
        final double raised = game.perspective
            .project(0, 1.4, GuzoCamera.playerZ)
            .dy;

        // Screen y grows downward, so higher in the world means smaller y.
        expect(raised, lessThan(grounded));
      },
    );

    testWithGame<GuzoGame>(
      'depth beyond the near plane never divides by zero',
      () => GuzoGame(seed: 1),
      (GuzoGame game) async {
        await game.ready();

        for (final double z in <double>[-10, 0, 0.001, 1, 50, 1000]) {
          final Offset point = game.perspective.project(2, 1, z);
          expect(point.dx.isFinite, isTrue, reason: 'z=$z gave $point');
          expect(point.dy.isFinite, isTrue, reason: 'z=$z gave $point');
        }
      },
    );
  });
}
