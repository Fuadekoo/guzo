import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../../widgets/guzo_icon.dart';
import '../../widgets/stat_pill.dart';
import '../guzo_game.dart';
import 'sequence_progress.dart';

/// The in-run heads-up display drawn on top of the Flame canvas.
///
/// Laid out like the reference design's top bar: a circular button on the
/// left, live pills on the right. Phase 3 adds the educational sequence
/// tracker under this row and Phase 4 the coin counter and boost timer.
///
/// Each read-out is its own [ValueListenableBuilder], so a change to the
/// distance does not rebuild the speed pill and vice versa — the HUD never
/// rebuilds wholesale at 60 fps.
class GameHud extends StatelessWidget {
  const GameHud({required this.game, required this.onPause, super.key});

  final GuzoGame game;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(GuzoSizes.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleIconButton(
                  icon: Icons.pause_rounded,
                  onPressed: onPause,
                  tooltip: GuzoStrings.paused,
                ),
                const Spacer(),
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
            ),
            const SizedBox(height: GuzoSizes.spaceSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                const GuzoIcon(GuzoIconAsset.boost, size: 20),
                const SizedBox(width: GuzoSizes.spaceXs + 2),
                ValueListenableBuilder<double>(
                  valueListenable: game.speedNotifier,
                  builder: (BuildContext context, double speed, _) =>
                      _SpeedBar(speed: speed),
                ),
              ],
            ),
            const SizedBox(height: GuzoSizes.spaceMd),
            // The educational goal sits centre stage, below the run stats:
            // it is what the player is actually here for.
            Center(child: SequenceProgress(game: game)),
          ],
        ),
      ),
    );
  }
}

/// A small bar showing how close the run is to top speed.
///
/// Doubles as the stumble indicator: the fill drops sharply on a hit, which is
/// the clearest way to show a child that bumping something costs them.
class _SpeedBar extends StatelessWidget {
  const _SpeedBar({required this.speed});

  final double speed;

  @override
  Widget build(BuildContext context) {
    final double fraction = (speed / GuzoWorld.maxSpeed)
        .clamp(0.0, 1.0)
        .toDouble();
    final bool slowed = speed < GuzoWorld.startSpeed * 0.8;

    return Container(
      width: 118,
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
              color: slowed ? GuzoColors.danger : GuzoCategoryColors.numbers,
              borderRadius: BorderRadius.circular(GuzoSizes.radiusPill),
            ),
          ),
        ),
      ),
    );
  }
}
