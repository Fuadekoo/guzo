import '../../utils/constants.dart';
import '../player/player_controller.dart';
import '../world/coin.dart';
import 'boost_controller.dart';

/// Picks up coins the runner touches.
///
/// The same shape as [CollectionSystem] but far simpler: a coin has no target
/// to match and no sequence to advance, so a touch is always just a touch.
class CoinSystem {
  /// Ids already collected this run, so a coin cannot be banked twice.
  ///
  /// Bounded by the coins actually passed, so it never needs pruning. In
  /// multiplayer the host keeps one of these per player.
  final Set<int> _consumed = <int>{};

  /// Depth window that should be searched around the runner, in metres.
  static const double searchWindow = 3.0;

  int get consumedCount => _consumed.length;

  /// Collects any coins the runner overlaps, crediting [wallet].
  ///
  /// Returns how many were taken this frame, which the caller turns into a
  /// sound and a HUD bump.
  int collect(
    PlayerController player,
    Iterable<Coin> candidates,
    CoinWallet wallet,
    double playerWorldZ,
  ) {
    int taken = 0;

    final double playerBottom = player.y;
    final double playerTop = player.y + player.height;

    for (final Coin coin in candidates) {
      if (_consumed.contains(coin.id)) continue;
      if (!_overlaps(coin, player, playerWorldZ, playerBottom, playerTop)) {
        continue;
      }

      _consumed.add(coin.id);
      wallet.add();
      taken++;
    }

    return taken;
  }

  bool _overlaps(
    Coin coin,
    PlayerController player,
    double playerWorldZ,
    double playerBottom,
    double playerTop,
  ) {
    // Depth first — it rejects almost everything for the least work.
    const double depthReach =
        GuzoEconomy.coinHalfDepth + GuzoWorld.playerHalfDepth;
    if ((coin.worldZ - playerWorldZ).abs() > depthReach) return false;

    const double sideReach =
        GuzoEconomy.coinHalfWidth + GuzoWorld.playerHalfWidth;
    if ((coin.x - player.x).abs() > sideReach) return false;

    final double bottom = coin.height - GuzoEconomy.coinHalfHeight;
    final double top = coin.height + GuzoEconomy.coinHalfHeight;
    return playerBottom < top && playerTop > bottom;
  }

  /// True when this coin has been banked and should stop drawing.
  bool isConsumed(Coin coin) => _consumed.contains(coin.id);

  void reset() => _consumed.clear();
}
