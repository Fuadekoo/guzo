import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// One tile in the home screen's category grid.
///
/// Built like [GuzoButton]: a deeper slab behind a coloured face that sinks on
/// press. Children get an unmistakable physical response without any animation
/// assets, and it works the same on a cheap 60 Hz panel as on a fast one.
class CategoryTile extends StatefulWidget {
  const CategoryTile({
    required this.label,
    required this.glyph,
    required this.color,
    required this.shadowColor,
    required this.onPressed,
    this.subtitle,
    super.key,
  });

  final String label;

  /// A short piece of text drawn large as the tile's emblem — "ABC", "123",
  /// "ሀሁሂ". Text rather than an icon so the Amharic tile can show real Fidel.
  final String glyph;

  final String? subtitle;
  final Color color;
  final Color shadowColor;
  final VoidCallback onPressed;

  static const double _depth = 6;

  @override
  State<CategoryTile> createState() => _CategoryTileState();
}

class _CategoryTileState extends State<CategoryTile> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              top: CategoryTile._depth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: widget.shadowColor,
                  borderRadius: BorderRadius.circular(GuzoSizes.radiusLg),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 70),
              curve: Curves.easeOut,
              left: 0,
              right: 0,
              top: _pressed ? CategoryTile._depth : 0,
              bottom: _pressed ? 0 : CategoryTile._depth,
              child: _buildFace(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFace(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(GuzoSizes.radiusLg),
      ),
      padding: const EdgeInsets.all(GuzoSizes.spaceMd),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Center(
              child: FittedBox(
                child: Text(
                  widget.glyph,
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w900,
                    color: GuzoColors.onPrimary,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: GuzoSizes.spaceSm),
          Text(
            widget.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: GuzoColors.onPrimary,
            ),
          ),
          if (widget.subtitle != null)
            Text(
              widget.subtitle!,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: GuzoColors.onPrimary.withValues(alpha: 0.85),
              ),
            ),
        ],
      ),
    );
  }
}
