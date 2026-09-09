import 'package:flutter/material.dart';

import '../../education/sequence_tracker.dart';
import '../../utils/constants.dart';
import '../guzo_game.dart';

/// The educational progress display: what to collect next, and how far along.
///
/// The brief sketches this as a vertical checklist:
///
/// ```
/// A ✓
/// B ✓
/// C →
/// D
/// ```
///
/// On a portrait phone a 26-row list would swallow the screen, so the same
/// information is laid out horizontally: a large target badge for the item due
/// now, a sliding ribbon of neighbours showing what is done and what is
/// coming, and a count. The ribbon window follows the target, so the run
/// always reads in context rather than jumping to the top of an alphabet.
class SequenceProgress extends StatelessWidget {
  const SequenceProgress({required this.game, super.key});

  final GuzoGame game;

  /// Items shown either side of the target in the ribbon.
  static const int _windowSize = 7;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.collectedCount,
      builder: (BuildContext context, _, Widget? child) {
        final SequenceTracker tracker = game.tracker;

        return Column(
          children: <Widget>[
            ValueListenableBuilder<PickupFeedback>(
              valueListenable: game.feedback,
              builder:
                  (
                    BuildContext context,
                    PickupFeedback feedback,
                    Widget? child,
                  ) => _TargetBadge(
                    target: tracker.currentTarget,
                    feedback: feedback,
                    fontFamilyFallback: tracker.definition.fontFamilyFallback,
                  ),
            ),
            const SizedBox(height: GuzoSizes.spaceSm),
            _Ribbon(
              slots: tracker.window(_windowSize),
              fontFamilyFallback: tracker.definition.fontFamilyFallback,
            ),
            const SizedBox(height: GuzoSizes.spaceXs + 2),
            _CountLabel(
              collected: tracker.collectedCount,
              total: tracker.totalCount,
            ),
          ],
        );
      },
    );
  }
}

/// The big "collect this next" badge.
class _TargetBadge extends StatelessWidget {
  const _TargetBadge({
    required this.target,
    required this.feedback,
    required this.fontFamilyFallback,
  });

  final String? target;
  final PickupFeedback feedback;
  final List<String>? fontFamilyFallback;

  Color get _background {
    switch (feedback) {
      case PickupFeedback.correct:
      case PickupFeedback.finished:
        return GuzoColors.correctFlash;
      case PickupFeedback.wrong:
        return GuzoColors.wrongFlash;
      case PickupFeedback.none:
        return GuzoColors.targetTile;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (target == null) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: _background,
        shape: BoxShape.circle,
        border: Border.all(color: GuzoColors.targetTileEdge, width: 3),
        boxShadow: GuzoShadows.pill,
      ),
      alignment: Alignment.center,
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            target!,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: GuzoColors.targetGlyph,
              fontFamilyFallback: fontFamilyFallback,
            ),
          ),
        ),
      ),
    );
  }
}

/// The sliding strip of collected, current and upcoming items.
class _Ribbon extends StatelessWidget {
  const _Ribbon({required this.slots, required this.fontFamilyFallback});

  final List<SequenceSlot> slots;
  final List<String>? fontFamilyFallback;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: GuzoColors.scrim,
        borderRadius: BorderRadius.circular(GuzoSizes.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final SequenceSlot slot in slots)
            _RibbonItem(slot: slot, fontFamilyFallback: fontFamilyFallback),
        ],
      ),
    );
  }
}

class _RibbonItem extends StatelessWidget {
  const _RibbonItem({required this.slot, required this.fontFamilyFallback});

  final SequenceSlot slot;
  final List<String>? fontFamilyFallback;

  @override
  Widget build(BuildContext context) {
    // Three states, three treatments: done is a green tick, current is the
    // filled marker, upcoming is dimmed.
    final Color background = slot.collected
        ? GuzoColors.correctFlash
        : slot.isCurrent
        ? GuzoColors.targetTile
        : Colors.transparent;
    final Color foreground = slot.collected
        ? GuzoColors.onPrimary
        : slot.isCurrent
        ? GuzoColors.targetGlyph
        : GuzoColors.onPrimary.withValues(alpha: 0.5);

    return Container(
      width: 26,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(GuzoSizes.radiusSm),
      ),
      alignment: Alignment.center,
      child: slot.collected
          ? const Icon(
              Icons.check_rounded,
              size: 16,
              color: GuzoColors.onPrimary,
            )
          : FittedBox(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  slot.value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: foreground,
                    fontFamilyFallback: fontFamilyFallback,
                  ),
                ),
              ),
            ),
    );
  }
}

class _CountLabel extends StatelessWidget {
  const _CountLabel({required this.collected, required this.total});

  final int collected;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: GuzoColors.scrim,
        borderRadius: BorderRadius.circular(GuzoSizes.radiusPill),
      ),
      child: Text(
        '$collected / $total',
        style: const TextStyle(
          color: GuzoColors.onPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
