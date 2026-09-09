import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guzo/education/sequence_library.dart';
import 'package:guzo/game/guzo_game.dart';
import 'package:guzo/game/input/swipe_recognizer.dart';
import 'package:guzo/game/world/coin.dart';
import 'package:guzo/game/world/collectible.dart';
import 'package:guzo/game/world/track_chunk.dart';
import 'package:guzo/game/world/world_generator.dart';
import 'package:guzo/services/audio_service.dart';
import 'package:guzo/utils/constants.dart';

import 'support/recording_audio.dart';

void _run(GuzoGame game, double seconds) {
  const double step = 1 / 60;
  for (double t = 0; t < seconds; t += step) {
    game.update(step);
  }
}

/// Builds a game wired to a recording audio double.
GuzoGame Function() _gameWith(RecordingGameAudio audio, {int seed = 7}) =>
    () => GuzoGame(seed: seed, audio: audio);

void main() {
  group('Coin generation', () {
    test('coins appear and are deterministic for a seed', () {
      List<String> signature(TrackChunk chunk) => <String>[
        for (final Coin c in chunk.coins) '${c.id}:${c.worldZ}:${c.lane}',
      ];

      final TrackChunk a = WorldGenerator(seed: 31).generateChunk(3);
      final TrackChunk b = WorldGenerator(seed: 31).generateChunk(3);

      expect(a.coins, isNotEmpty);
      expect(signature(a), signature(b));
    });

    test('a coin run never shares a lane with the letters beside it', () {
      // This is the whole point of the coin placement: the player has to
      // choose between the letter they need and the coins that buy a boost.
      for (int seed = 0; seed < 10; seed++) {
        final WorldGenerator generator = WorldGenerator(seed: seed);

        for (int index = 0; index < 15; index++) {
          final TrackChunk chunk = generator.generateChunk(index);

          for (final Coin coin in chunk.coins) {
            for (final Collectible tile in chunk.collectibles) {
              if ((coin.worldZ - tile.worldZ).abs() > 2) continue;
              expect(
                coin.lane,
                isNot(tile.lane),
                reason:
                    'seed $seed: a coin and a letter share lane '
                    '${coin.lane} at ${coin.worldZ} m',
              );
            }
          }
        }
      }
    });

    test('coins stay in real lanes and within jumping reach', () {
      final double reach = GuzoEconomy.coinHeight + GuzoEconomy.coinArcLift;
      // The top of an arc must be inside a jump's reach, or the run is a tease.
      expect(
        reach - GuzoEconomy.coinHalfHeight,
        lessThan(GuzoWorld.jumpPeakHeight + GuzoWorld.playerHeight),
      );

      final WorldGenerator generator = WorldGenerator(seed: 88);
      for (int index = 0; index < 20; index++) {
        for (final Coin coin in generator.generateChunk(index).coins) {
          expect(coin.lane, inInclusiveRange(-1, 1));
          expect(coin.height, greaterThanOrEqualTo(GuzoEconomy.coinHeight));
          expect(coin.height, lessThanOrEqualTo(reach + 0.001));
        }
      }
    });

    test('coin ids are unique across a long run', () {
      final WorldGenerator generator = WorldGenerator(seed: 404);
      final Set<int> ids = <int>{};
      int total = 0;

      for (int index = 0; index < 40; index++) {
        for (final Coin coin in generator.generateChunk(index).coins) {
          ids.add(coin.id);
          total++;
        }
      }

      expect(ids.length, total);
    });

    test('coins are ordered by distance for the render merge', () {
      final WorldGenerator generator = WorldGenerator(seed: 6);

      for (int index = 0; index < 15; index++) {
        final List<Coin> coins = generator.generateChunk(index).coins;
        for (int i = 1; i < coins.length; i++) {
          expect(coins[i].worldZ, greaterThanOrEqualTo(coins[i - 1].worldZ));
        }
      }
    });
  });

  group('Collecting during a run', () {
    // Created once and cleared between tests, not `late` + assigned in setUp:
    // testWithGame takes its game factory eagerly, so the factory would read
    // the variable before setUp had ever run.
    final RecordingGameAudio audio = RecordingGameAudio();

    setUp(audio.clear);

    testWithGame<GuzoGame>(
      'banks coins and reports them to the HUD',
      _gameWith(audio),
      (GuzoGame game) async {
        await game.ready();
        expect(game.coins.value, 0);

        _run(game, 60);

        expect(game.wallet.coins, greaterThan(0));
        expect(game.coins.value, game.wallet.coins);
        expect(audio.didPlay(GuzoSound.coin), isTrue);
      },
    );

    testWithGame<GuzoGame>(
      'plays a sound for every kind of pickup and knock',
      _gameWith(audio),
      (GuzoGame game) async {
        await game.ready();
        _run(game, 90);

        expect(audio.didPlay(GuzoSound.coin), isTrue);
        expect(
          audio.didPlay(GuzoSound.correct) || audio.didPlay(GuzoSound.wrong),
          isTrue,
          reason: 'a 90 s run should touch at least one letter tile',
        );
        expect(audio.didPlay(GuzoSound.hit), isTrue);
      },
    );

    testWithGame<GuzoGame>(
      'jumping and sliding are audible',
      _gameWith(audio),
      (GuzoGame game) async {
        await game.ready();

        game.applySwipe(SwipeDirection.up);
        expect(audio.didPlay(GuzoSound.jump), isTrue);

        _run(game, 1);
        game.applySwipe(SwipeDirection.down);
        expect(audio.didPlay(GuzoSound.slide), isTrue);
      },
    );
  });

  group('Boost in a live run', () {
    // Created once and cleared between tests, not `late` + assigned in setUp:
    // testWithGame takes its game factory eagerly, so the factory would read
    // the variable before setUp had ever run.
    final RecordingGameAudio audio = RecordingGameAudio();

    setUp(audio.clear);

    testWithGame<GuzoGame>(
      'cannot be bought with an empty wallet',
      _gameWith(audio),
      (GuzoGame game) async {
        await game.ready();

        expect(game.canBoost, isFalse);
        expect(game.activateBoost(), isFalse);
        expect(audio.didPlay(GuzoSound.boost), isFalse);
      },
    );

    testWithGame<GuzoGame>(
      'spends coins, speeds the runner up and sounds off',
      _gameWith(audio),
      (GuzoGame game) async {
        await game.ready();
        game.wallet.add(GuzoEconomy.boostCost);

        final double before = game.speed;
        expect(game.canBoost, isTrue);
        expect(game.activateBoost(), isTrue);

        expect(game.coins.value, 0);
        expect(game.speed, closeTo(before * GuzoEconomy.boostMultiplier, 0.01));
        expect(audio.didPlay(GuzoSound.boost), isTrue);
      },
    );

    testWithGame<GuzoGame>(
      'covers more ground than an unboosted run over the same time',
      () => GuzoGame(seed: 7, audio: SilentGameAudio()),
      (GuzoGame boosted) async {
        await boosted.ready();
        boosted.wallet.add(GuzoEconomy.boostCost);
        boosted.activateBoost();
        _run(boosted, GuzoEconomy.boostDuration);

        final GuzoGame plain = GuzoGame(seed: 7, audio: SilentGameAudio());
        plain.onGameResize(boosted.size);
        await plain.ready();
        _run(plain, GuzoEconomy.boostDuration);

        expect(boosted.distance, greaterThan(plain.distance));
      },
    );

    testWithGame<GuzoGame>(
      'bursts through obstacles instead of stumbling',
      _gameWith(audio),
      (GuzoGame game) async {
        await game.ready();
        // Get past the warm-up, then boost through the obstacle field.
        _run(game, 8);
        game.wallet.add(GuzoEconomy.boostCost);
        game.activateBoost();

        final int stumblesBefore = game.stumbles.value;
        _run(game, GuzoEconomy.boostDuration - 0.1);

        expect(
          game.stumbles.value,
          stumblesBefore,
          reason: 'a boosting runner should not stumble',
        );
      },
    );

    testWithGame<GuzoGame>(
      'widens the camera while boosting and settles back after',
      _gameWith(audio),
      (GuzoGame game) async {
        await game.ready();
        expect(game.perspective.boostZoom, closeTo(1, 0.001));

        game.wallet.add(GuzoEconomy.boostCost);
        game.activateBoost();
        _run(game, 1);

        expect(game.perspective.boostZoom, lessThan(1));

        _run(game, GuzoEconomy.boostDuration + 2);
        expect(game.perspective.boostZoom, closeTo(1, 0.01));
      },
    );

    testWithGame<GuzoGame>(
      'reports the countdown to the HUD and clears it at the end',
      _gameWith(audio),
      (GuzoGame game) async {
        await game.ready();
        game.wallet.add(GuzoEconomy.boostCost);
        game.activateBoost();
        _run(game, 1);

        expect(game.boostRemaining.value, greaterThan(0));
        expect(game.boostRemaining.value, lessThan(GuzoEconomy.boostDuration));

        _run(game, GuzoEconomy.boostDuration);
        expect(game.boostRemaining.value, 0);
      },
    );

    testWithGame<GuzoGame>(
      'is refused once the sequence is over',
      () => GuzoGame(
        seed: 7,
        sequence: SequenceLibrary.englishVowels,
        audio: SilentGameAudio(),
      ),
      (GuzoGame game) async {
        await game.ready();
        game.wallet.add(GuzoEconomy.boostCost);
        game.isComplete.value = true;

        expect(game.canBoost, isFalse);
        expect(game.activateBoost(), isFalse);
      },
    );
  });

  group('Restart', () {
    testWithGame<GuzoGame>(
      'clears coins and any running boost',
      () => GuzoGame(seed: 7, audio: SilentGameAudio()),
      (GuzoGame game) async {
        await game.ready();
        _run(game, 40);
        game.wallet.add(GuzoEconomy.boostCost);
        game.activateBoost();

        game.restart();

        expect(game.wallet.coins, 0);
        expect(game.coins.value, 0);
        expect(game.boost.isActive, isFalse);
        expect(game.boostRemaining.value, 0);
        expect(game.coinPickups.consumedCount, 0);
        expect(game.perspective.boostZoom, 1);
      },
    );
  });
}
