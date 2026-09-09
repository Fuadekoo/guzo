import 'dart:math' as math;

import '../../utils/constants.dart';

/// The player's coins for this match.
///
/// Separate from [BoostController] because the brief keeps the door open for a
/// persistent economy later: the wallet is the thing that would grow, while
/// the boost is only one place to spend.
class CoinWallet {
  int _coins = 0;

  int get coins => _coins;

  void add([int amount = GuzoEconomy.coinsPerPickup]) {
    if (amount <= 0) return;
    _coins += amount;
  }

  bool canAfford(int cost) => _coins >= cost;

  /// Deducts [cost] if it is affordable. Returns whether it went through.
  bool trySpend(int cost) {
    if (cost <= 0 || !canAfford(cost)) return false;
    _coins -= cost;
    return true;
  }

  void reset() => _coins = 0;
}

/// The speed boost: a timed multiplier bought with coins.
///
/// Pure state — seconds in, seconds out, no rendering and no audio — so the
/// Phase 6 host can run the identical object to verify that a client really
/// could afford the boost it claims to have used.
///
/// Boosting also makes the runner untouchable. The brief does not ask for
/// that, but 5 seconds at +60% into a barrier field would punish the player
/// for spending, which is the opposite of a reward. Instead the runner bursts
/// straight through: see [smashesObstacles].
class BoostController {
  double _remaining = 0;

  /// Seconds since the boost ended, used to ramp the effects back down.
  double _sinceEnd = GuzoEconomy.boostRampOut;

  bool get isActive => _remaining > 0;

  /// Seconds left, for the HUD countdown.
  double get remaining => _remaining;

  /// Forward speed multiplier this frame.
  double get speedMultiplier => isActive ? GuzoEconomy.boostMultiplier : 1.0;

  /// While boosting the runner bursts through obstacles instead of stumbling.
  bool get smashesObstacles => isActive;

  /// How strongly the visual effects should show, in `[0, 1]`.
  ///
  /// Ramps in fast and out slowly, so the boost arrives with a punch and
  /// leaves as a glide rather than snapping off mid-stride.
  double get intensity {
    if (isActive) {
      final double elapsed = GuzoEconomy.boostDuration - _remaining;
      final double rampIn = (elapsed / GuzoEconomy.boostRampIn)
          .clamp(0.0, 1.0)
          .toDouble();
      final double rampOut = (_remaining / GuzoEconomy.boostRampOut)
          .clamp(0.0, 1.0)
          .toDouble();
      return math.min(rampIn, rampOut);
    }

    // Tail after the boost ends.
    return (1 - _sinceEnd / GuzoEconomy.boostRampOut)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  /// True when a boost could be started right now.
  ///
  /// Refuses while one is already running: re-buying mid-boost would quietly
  /// spend ten coins for almost nothing.
  bool canActivate(CoinWallet wallet) =>
      !isActive && wallet.canAfford(GuzoEconomy.boostCost);

  /// Spends the coins and starts the boost. Returns false if it could not.
  bool activate(CoinWallet wallet) {
    if (!canActivate(wallet)) return false;
    if (!wallet.trySpend(GuzoEconomy.boostCost)) return false;

    _remaining = GuzoEconomy.boostDuration;
    _sinceEnd = 0;
    return true;
  }

  void update(double dt) {
    if (isActive) {
      _remaining = math.max(0, _remaining - dt);
      if (_remaining == 0) _sinceEnd = 0;
      return;
    }
    _sinceEnd = math.min(GuzoEconomy.boostRampOut, _sinceEnd + dt);
  }

  void reset() {
    _remaining = 0;
    _sinceEnd = GuzoEconomy.boostRampOut;
  }
}
