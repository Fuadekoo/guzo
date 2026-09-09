import 'package:flutter/material.dart';

import '../utils/constants.dart';
import 'guzo_icon.dart';

/// A rounded chip holding one illustrated icon and one value.
///
/// Used for the coin, distance and lives read-outs in both the home header and
/// the in-game HUD, so the two never drift apart visually.
class StatPill extends StatelessWidget {
  const StatPill({
    required this.icon,
    required this.label,
    this.background = GuzoColors.surface,
    this.foreground = GuzoColors.ink,
    this.compact = false,
    super.key,
  });

  final GuzoIconAsset icon;
  final String label;
  final Color background;
  final Color foreground;

  /// Tightens the padding for dense placements like the HUD.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double iconSize = compact ? 18 : 22;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? GuzoSizes.spaceSm + 2 : GuzoSizes.spaceMd - 2,
        vertical: compact ? 5 : GuzoSizes.spaceSm - 1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(GuzoSizes.radiusPill),
        boxShadow: GuzoShadows.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          GuzoIcon(icon, size: iconSize),
          const SizedBox(width: GuzoSizes.spaceXs + 2),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 14 : 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// A circular icon button on a raised white disc.
///
/// Takes a Material [IconData] rather than a [GuzoIconAsset]: this is UI
/// chrome (pause, back, settings), not game content.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.background = GuzoColors.surface,
    this.foreground = GuzoColors.ink,
    super.key,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        boxShadow: GuzoShadows.pill,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: IconButton(
          onPressed: onPressed,
          tooltip: tooltip,
          iconSize: 24,
          color: foreground,
          constraints: const BoxConstraints.tightFor(
            width: GuzoSizes.iconButtonSize,
            height: GuzoSizes.iconButtonSize,
          ),
          icon: Icon(icon),
        ),
      ),
    );
  }
}
