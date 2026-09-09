import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../../widgets/guzo_button.dart';
import '../../widgets/guzo_icon.dart';
import '../guzo_game.dart';

/// Shown when a player finishes their sequence.
///
/// A deliberately small version of the result screen: Phase 4 grows this into
/// the full one with coins earned, and Phase 6 adds the finishing positions of
/// the other players. It exists now because a completed sequence must lead
/// somewhere — leaving it to do nothing would be a dead end.
class CompleteOverlay extends StatelessWidget {
  const CompleteOverlay({
    required this.game,
    required this.onPlayAgain,
    required this.onHome,
    super.key,
  });

  final GuzoGame game;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  static String formatTime(double seconds) {
    final int total = seconds.round();
    final String mm = (total ~/ 60).toString().padLeft(2, '0');
    final String ss = (total % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: GuzoColors.scrim,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(GuzoSizes.spaceLg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: GuzoSizes.buttonMaxWidth,
            ),
            child: Container(
              padding: const EdgeInsets.all(GuzoSizes.spaceLg),
              decoration: BoxDecoration(
                color: GuzoColors.surface,
                borderRadius: BorderRadius.circular(GuzoSizes.radiusLg),
                boxShadow: GuzoShadows.card,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const GuzoIcon(GuzoIconAsset.trophy, size: 68),
                  const SizedBox(height: GuzoSizes.spaceSm),
                  Text(
                    GuzoStrings.sequenceComplete,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: GuzoSizes.spaceXs),
                  Text(
                    game.sequence.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: GuzoSizes.spaceLg),
                  _StatsRow(game: game),
                  const SizedBox(height: GuzoSizes.spaceLg),
                  GuzoButton(
                    label: GuzoStrings.playAgain,
                    icon: Icons.replay_rounded,
                    onPressed: onPlayAgain,
                  ),
                  const SizedBox(height: GuzoSizes.spaceMd),
                  GuzoButton(
                    label: GuzoStrings.home,
                    icon: Icons.home_rounded,
                    color: GuzoColors.secondary,
                    shadowColor: GuzoColors.secondaryDark,
                    onPressed: onHome,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.game});

  final GuzoGame game;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _Stat(
          label: GuzoStrings.statTime,
          value: CompleteOverlay.formatTime(game.runTime),
        ),
        _Stat(
          label: GuzoStrings.statDistance,
          value: '${game.distance.round()} m',
        ),
        _Stat(
          label: GuzoStrings.statCollected,
          value: '${game.tracker.totalCount}',
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: GuzoColors.ink,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: GuzoColors.inkSoft,
          ),
        ),
      ],
    );
  }
}
