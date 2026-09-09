import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../../widgets/guzo_icon.dart';
import '../../widgets/stat_pill.dart';
import '../guzo_game.dart';
import 'boost_button.dart';
import 'sequence_progress.dart';

/// The in-run heads-up display drawn on top of the Flame canvas.
///
/// Three bands, ordered by how often a child needs them: run stats along the
/// top, the educational goal centred beneath (it is what they are here for),
/// and the boost button pinned bottom-right under the thumb.
///
/// Each read-out is its own [ValueListenableBuilder], so a change to the coin
/// count does not rebuild the distance pill — the HUD never rebuilds wholesale
/// at 60 fps.
class GameHud extends StatelessWidget {
  const GameHud({required this.game, required this.onPause, super.key});

  final GuzoGame game;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(GuzoSizes.spaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildTopBar(),
                  const SizedBox(height: GuzoSizes.spaceSm),
                  _buildSpeedRow(),
                  const SizedBox(height: GuzoSizes.spaceMd),
                  Center(child: SequenceProgress(game: game)),
                ],
              ),
            ),
          ),
          Positioned(
            right: GuzoSizes.spaceMd,
            bottom: GuzoSizes.spaceLg,
            child: BoostButton(game: game),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: <Widget>[
        CircleIconButton(
          icon: Icons.pause_rounded,
          onPressed: onPause,
          tooltip: GuzoStrings.paused,
        ),
        const Spacer(),
        ValueListenableBuilder<int>(
          valueListenable: game.coins,
          builder: (BuildContext context, int coins, _) => StatPill(
            icon: GuzoIconAsset.coin,
            label: '$coins',
            compact: true,
          ),
        ),
        const SizedBox(width: GuzoSizes.spaceSm),
        ValueListenableBuilder<int>(
          valueListenable: game.distanceMetres,
          builder: (BuildContext context, int metres, _) => StatPill(
            icon: GuzoIconAsset.distance,
            label: '$metres m',
            compact: true,
          ),
        ),
        const SizedBox(width: GuzoSizes.spaceSm),
        ValueListenableBuilder<int>(
          valueListenable: game.stumbles,
          builder: (BuildContext context, int hits, _) => StatPill(
            icon: GuzoIconAsset.heart,
            label: '$hits',
            compact: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        ValueListenableBuilder<double>(
          valueListenable: game.speedNotifier,
          builder: (BuildContext context, double speed, _) =>
              ValueListenableBuilder<double>(
                valueListenable: game.boostRemaining,
                builder: (BuildContext context, double boost, _) =>
                    _SpeedBar(speed: speed, boosting: boost > 0),
              ),
        ),
      ],
    );
  }
}

/// A small bar showing how close the run is to top speed.
///
/// Carries both speed signals: the fill drops sharply and turns red on a
/// stumble, and turns teal and runs fuller than it otherwise ever does while
/// boosting.
class _SpeedBar extends StatelessWidget {
  const _SpeedBar({required this.speed, required this.boosting});

  final double speed;
  final bool boosting;

  @override
  Widget build(BuildContext context) {
    // Scaled against the *boosted* maximum, so a boost visibly overfills the
    // bar rather than pinning it at the same full it reaches unboosted.
    const double ceiling = GuzoWorld.maxSpeed * GuzoEconomy.boostMultiplier;
    final double fraction = (speed / ceiling).clamp(0.0, 1.0).toDouble();
    final bool slowed = speed < GuzoWorld.startSpeed * 0.8;

    return Container(
      width: 130,
      height: 14,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: GuzoColors.surface,
        borderRadius: BorderRadius.circular(GuzoSizes.radiusPill),
        boxShadow: GuzoShadows.pill,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              color: boosting
                  ? GuzoColors.boostGlow
                  : slowed
                  ? GuzoColors.danger
                  : GuzoCategoryColors.numbers,
              borderRadius: BorderRadius.circular(GuzoSizes.radiusPill),
            ),
          ),
        ),
      ),
    );
  }
}
