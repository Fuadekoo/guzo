import 'package:flutter_test/flutter_test.dart';
import 'package:guzo/game/systems/boost_controller.dart';
import 'package:guzo/utils/constants.dart';

void main() {
  group('CoinWallet', () {
    test('starts empty and banks coins', () {
      final CoinWallet wallet = CoinWallet();
      expect(wallet.coins, 0);

      wallet.add();
      wallet.add();

      expect(wallet.coins, 2 * GuzoEconomy.coinsPerPickup);
    });

    test('ignores a non-positive credit', () {
      final CoinWallet wallet = CoinWallet()
        ..add(5)
        ..add(0)
        ..add(-3);

      expect(wallet.coins, 5);
    });

    test('spends only what it can afford', () {
      final CoinWallet wallet = CoinWallet()..add(7);

      expect(wallet.canAfford(10), isFalse);
      expect(wallet.trySpend(10), isFalse);
      expect(wallet.coins, 7, reason: 'a refused purchase must not deduct');

      expect(wallet.trySpend(7), isTrue);
      expect(wallet.coins, 0);
    });

    test('reset empties the wallet', () {
      final CoinWallet wallet = CoinWallet()..add(20);
      wallet.reset();
      expect(wallet.coins, 0);
    });
  });

  group('Activation', () {
    late CoinWallet wallet;
    late BoostController boost;

    setUp(() {
      wallet = CoinWallet();
      boost = BoostController();
    });

    test('is refused without enough coins, and costs nothing', () {
      wallet.add(GuzoEconomy.boostCost - 1);

      expect(boost.canActivate(wallet), isFalse);
      expect(boost.activate(wallet), isFalse);
      expect(boost.isActive, isFalse);
      expect(wallet.coins, GuzoEconomy.boostCost - 1);
    });

    test('spends exactly the cost and starts', () {
      wallet.add(GuzoEconomy.boostCost + 3);

      expect(boost.activate(wallet), isTrue);
      expect(boost.isActive, isTrue);
      expect(wallet.coins, 3);
      expect(boost.remaining, GuzoEconomy.boostDuration);
    });

    test('is refused while one is already running', () {
      wallet.add(GuzoEconomy.boostCost * 3);
      boost.activate(wallet);
      final int afterFirst = wallet.coins;

      // Re-buying mid-boost would quietly burn ten coins for almost nothing.
      expect(boost.canActivate(wallet), isFalse);
      expect(boost.activate(wallet), isFalse);
      expect(wallet.coins, afterFirst);
    });

    test('can be bought again once the first has run out', () {
      wallet.add(GuzoEconomy.boostCost * 2);
      boost.activate(wallet);
      boost.update(GuzoEconomy.boostDuration + 0.1);

      expect(boost.isActive, isFalse);
      expect(boost.activate(wallet), isTrue);
    });
  });

  group('Running', () {
    late CoinWallet wallet;
    late BoostController boost;

    setUp(() {
      wallet = CoinWallet()..add(GuzoEconomy.boostCost);
      boost = BoostController();
    });

    test('multiplies speed by the documented amount, then stops', () {
      expect(boost.speedMultiplier, 1.0);

      boost.activate(wallet);
      expect(boost.speedMultiplier, GuzoEconomy.boostMultiplier);

      boost.update(GuzoEconomy.boostDuration + 0.01);
      expect(boost.speedMultiplier, 1.0);
    });

    test('counts down and never goes negative', () {
      boost.activate(wallet);

      boost.update(2);
      expect(boost.remaining, closeTo(GuzoEconomy.boostDuration - 2, 0.001));

      boost.update(100);
      expect(boost.remaining, 0);
      expect(boost.isActive, isFalse);
    });

    test('makes the runner burst through obstacles only while running', () {
      expect(boost.smashesObstacles, isFalse);

      boost.activate(wallet);
      expect(boost.smashesObstacles, isTrue);

      boost.update(GuzoEconomy.boostDuration + 0.01);
      expect(boost.smashesObstacles, isFalse);
    });
  });

  group('Effect intensity', () {
    late BoostController boost;

    setUp(() {
      boost = BoostController();
    });

    test('is zero at rest', () {
      expect(boost.intensity, 0);
    });

    test('ramps in rather than snapping on', () {
      boost.activate(CoinWallet()..add(GuzoEconomy.boostCost));
      expect(boost.intensity, 0);

      boost.update(GuzoEconomy.boostRampIn / 2);
      expect(boost.intensity, closeTo(0.5, 0.05));

      boost.update(GuzoEconomy.boostRampIn);
      expect(boost.intensity, 1.0);
    });

    test('ramps out as the boost expires', () {
      boost.activate(CoinWallet()..add(GuzoEconomy.boostCost));
      boost.update(GuzoEconomy.boostDuration - GuzoEconomy.boostRampOut / 2);

      expect(boost.intensity, lessThan(1));
      expect(boost.intensity, greaterThan(0));
    });

    test('tails off after the boost ends instead of cutting', () {
      boost.activate(CoinWallet()..add(GuzoEconomy.boostCost));
      boost.update(GuzoEconomy.boostDuration);

      expect(boost.isActive, isFalse);
      expect(boost.intensity, greaterThan(0), reason: 'effects should linger');

      boost.update(GuzoEconomy.boostRampOut);
      expect(boost.intensity, 0);
    });

    test('stays inside [0, 1] across a whole boost', () {
      boost.activate(CoinWallet()..add(GuzoEconomy.boostCost));

      for (double t = 0; t < GuzoEconomy.boostDuration + 2; t += 1 / 60) {
        expect(boost.intensity, inInclusiveRange(0, 1));
        boost.update(1 / 60);
      }
    });
  });

  group('Reset', () {
    test('clears an active boost and its after-effects', () {
      final BoostController boost = BoostController()
        ..activate(CoinWallet()..add(GuzoEconomy.boostCost));

      boost.reset();

      expect(boost.isActive, isFalse);
      expect(boost.remaining, 0);
      expect(boost.intensity, 0);
    });
  });
}
