import 'package:flutter/material.dart';

import '../game/guzo_game.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../widgets/guzo_button.dart';
import '../widgets/guzo_icon.dart';

/// Shown when a player finishes their sequence.
///
/// Rendered as an overlay on the frozen game rather than pushed as a route:
/// the finished world stays visible behind it, which reads as an ending rather
/// than a context switch, and there is no page transition between the last
/// letter and the trophy.
///
/// Phase 6 adds the finishing order of the other players below the stats; the
/// layout already leaves room.
class ResultScreen extends StatefulWidget {
  const ResultScreen({
    required this.game,
    required this.onPlayAgain,
    required this.onHome,
    super.key,
  });

  final GuzoGame game;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  /// Formats seconds as `MM:SS`, as the brief's mock-up shows.
  static String formatTime(double seconds) {
    final int total = seconds.round();
    final String mm = (total ~/ 60).toString().padLeft(2, '0');
    final String ss = (total % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  /// The record standing *before* this run, so "previous best" is meaningful.
  BestResult? _previousBest;
  bool _isNewRecord = false;

  @override
  void initState() {
    super.initState();
    _recordResult();
  }

  Future<void> _recordResult() async {
    final StorageService storage = StorageService.instance;
    final BestResult? previous = storage.bestFor(widget.game.sequence.id);

    final bool isRecord = await storage.recordResult(
      sequenceId: widget.game.sequence.id,
      seconds: widget.game.runTime,
      coins: widget.game.coins.value,
    );

    if (!mounted) return;
    setState(() {
      _previousBest = previous;
      _isNewRecord = isRecord;
    });
  }

  @override
  Widget build(BuildContext context) {
    final GuzoGame game = widget.game;

    return ColoredBox(
      color: GuzoColors.scrim,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(GuzoSizes.spaceMd),
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
                    const GuzoIcon(GuzoIconAsset.trophy, size: 76),
                    const SizedBox(height: GuzoSizes.spaceSm),
                    Text(
                      GuzoStrings.youWin,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 30,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: GuzoSizes.spaceXs),
                    Text(
                      '${game.sequence.name} • '
                      '${game.sequence.items.first}–${game.sequence.items.last}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamilyFallback: game.sequence.fontFamilyFallback,
                      ),
                    ),
                    if (_isNewRecord) ...<Widget>[
                      const SizedBox(height: GuzoSizes.spaceMd),
                      const _RecordBanner(),
                    ],
                    const SizedBox(height: GuzoSizes.spaceLg),
                    _StatsGrid(game: game),
                    if (_previousBest != null) ...<Widget>[
                      const SizedBox(height: GuzoSizes.spaceMd),
                      Text(
                        '${GuzoStrings.previousBest}: '
                        '${ResultScreen.formatTime(_previousBest!.seconds)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: GuzoSizes.spaceLg),
                    GuzoButton(
                      label: GuzoStrings.playAgain,
                      icon: Icons.replay_rounded,
                      onPressed: widget.onPlayAgain,
                    ),
                    const SizedBox(height: GuzoSizes.spaceMd),
                    GuzoButton(
                      label: GuzoStrings.home,
                      icon: Icons.home_rounded,
                      color: GuzoColors.secondary,
                      shadowColor: GuzoColors.secondaryDark,
                      onPressed: widget.onHome,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecordBanner extends StatelessWidget {
  const _RecordBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GuzoSizes.spaceMd,
        vertical: GuzoSizes.spaceSm,
      ),
      decoration: BoxDecoration(
        color: GuzoColors.correctFlash,
        borderRadius: BorderRadius.circular(GuzoSizes.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const GuzoIcon(GuzoIconAsset.star, size: 20),
          const SizedBox(width: GuzoSizes.spaceSm),
          Text(
            GuzoStrings.newRecord,
            style: const TextStyle(
              color: GuzoColors.onPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.game});

  final GuzoGame game;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _Stat(
              label: GuzoStrings.statTime,
              value: ResultScreen.formatTime(game.runTime),
              icon: GuzoIconAsset.trophy,
            ),
            _Stat(
              label: GuzoStrings.statCoins,
              value: '${game.coins.value}',
              icon: GuzoIconAsset.coin,
            ),
          ],
        ),
        const SizedBox(height: GuzoSizes.spaceMd),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _Stat(
              label: GuzoStrings.statDistance,
              value: '${game.distance.round()} m',
              icon: GuzoIconAsset.distance,
            ),
            _Stat(
              label: GuzoStrings.statStumbles,
              value: '${game.stumbles.value}',
              icon: GuzoIconAsset.heart,
            ),
          ],
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final GuzoIconAsset icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        children: <Widget>[
          GuzoIcon(icon, size: 26),
          const SizedBox(height: GuzoSizes.spaceXs),
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
      ),
    );
  }
}
