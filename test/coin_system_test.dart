import 'package:flutter_test/flutter_test.dart';
import 'package:guzo/game/player/player_controller.dart';
import 'package:guzo/game/systems/boost_controller.dart';
import 'package:guzo/game/systems/coin_system.dart';
import 'package:guzo/game/world/coin.dart';
import 'package:guzo/utils/constants.dart';

const double _playerZ = 100.0;

Coin _coin({int id = 1, int lane = 0, double? height, double? worldZ}) => Coin(
  id: id,
  worldZ: worldZ ?? _playerZ,
  lane: lane,
  height: height ?? GuzoEconomy.coinHeight,
);

void _advance(PlayerController player, double seconds) {
  const double step = 1 / 60;
  for (double t = 0; t < seconds; t += step) {
    player.update(step, 0);
  }
}

void main() {
  late CoinSystem coins;
  late CoinWallet wallet;
  late PlayerController player;

  setUp(() {
    coins = CoinSystem();
    wallet = CoinWallet();
    player = PlayerController();
  });

  int collect(List<Coin> candidates) =>
      coins.collect(player, candidates, wallet, _playerZ);

  group('Picking up', () {
    test('a coin in the runner\'s lane is banked', () {
      expect(collect(<Coin>[_coin()]), 1);
      expect(wallet.coins, GuzoEconomy.coinsPerPickup);
    });

    test('a whole run is banked in one pass', () {
      final List<Coin> run = <Coin>[
        for (int i = 0; i < 4; i++) _coin(id: i, worldZ: _playerZ + i * 0.1),
      ];

      expect(collect(run), 4);
      expect(wallet.coins, 4);
    });

    test('a coin in another lane is missed', () {
      player
        ..moveLeft()
        ..update(0.5, 0);

      expect(collect(<Coin>[_coin()]), 0);
      expect(wallet.coins, 0);
    });

    test('a coin further down the track is not yet reachable', () {
      expect(collect(<Coin>[_coin(worldZ: _playerZ + 20)]), 0);
    });

    test('the same coin cannot be banked twice', () {
      final List<Coin> same = <Coin>[_coin()];

      expect(collect(same), 1);
      expect(collect(same), 0);
      expect(wallet.coins, 1);
    });

    test('a banked coin reports itself so the painter can drop it', () {
      final Coin coin = _coin();
      expect(coins.isConsumed(coin), isFalse);

      collect(<Coin>[coin]);
      expect(coins.isConsumed(coin), isTrue);
    });

    test('an empty track banks nothing', () {
      expect(collect(<Coin>[]), 0);
    });
  });

  group('Height', () {
    test('a coin at the top of an arc needs a jump', () {
      final Coin high = _coin(
        height: GuzoEconomy.coinHeight + GuzoEconomy.coinArcLift,
      );

      expect(collect(<Coin>[high]), 0);

      player.jump();
      _advance(player, 0.2);
      expect(collect(<Coin>[high]), 1);
    });

    test('a resting coin is reachable while running or sliding', () {
      expect(collect(<Coin>[_coin(id: 1)]), 1);

      player.slide();
      expect(collect(<Coin>[_coin(id: 2)]), 1);
    });
  });

  group('Reset', () {
    test('clears the consumed set', () {
      final List<Coin> same = <Coin>[_coin()];
      collect(same);

      coins.reset();

      expect(collect(same), 1);
      expect(coins.consumedCount, 1);
    });
  });
}
