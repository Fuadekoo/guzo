import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// A large, chunky, child-friendly action button.
///
/// Draws a solid "shadow slab" underneath the face and sinks the face into it
/// while pressed, which gives an obvious physical response on cheap devices
/// without needing any animation assets.
class GuzoButton extends StatefulWidget {
  const GuzoButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = GuzoColors.primary,
    this.shadowColor = GuzoColors.primaryDark,
    this.enabled = true,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final Color shadowColor;
  final bool enabled;

  /// Vertical travel of the button face when pressed.
  static const double _depth = 6;

  @override
  State<GuzoButton> createState() => _GuzoButtonState();
}

class _GuzoButtonState extends State<GuzoButton> {
  bool _pressed = false;

  bool get _interactive => widget.enabled && widget.onPressed != null;

  void _setPressed(bool value) {
    if (!_interactive || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final double sink = _pressed ? GuzoButton._depth : 0;

    return Semantics(
      button: true,
      enabled: _interactive,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: _interactive ? widget.onPressed : null,
        child: Opacity(
          opacity: _interactive ? 1 : 0.45,
          child: SizedBox(
            height: GuzoSizes.buttonHeight + GuzoButton._depth,
            width: double.infinity,
            child: Stack(
              children: <Widget>[
                // Shadow slab.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: GuzoSizes.buttonHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.shadowColor,
                      borderRadius: BorderRadius.circular(GuzoSizes.radiusLg),
                    ),
                  ),
                ),
                // Button face.
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 70),
                  curve: Curves.easeOut,
                  left: 0,
                  right: 0,
                  top: sink,
                  height: GuzoSizes.buttonHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(GuzoSizes.radiusLg),
                    ),
                    child: Center(child: _buildContent(context)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final Text label = Text(
      widget.label,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelLarge,
    );

    if (widget.icon == null) return label;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(widget.icon, color: GuzoColors.onPrimary, size: 28),
        const SizedBox(width: GuzoSizes.spaceSm + GuzoSizes.spaceXs),
        Flexible(child: label),
      ],
    );
  }
}
