import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../../widgets/guzo_icon.dart';
import '../guzo_game.dart';

/// The button that spends coins on a speed boost.
///
/// It has three states and each is readable at a glance without reading a
/// number: **charging** (grey, showing how many more coins are needed),
/// **ready** (teal, pulsing), and **running** (showing the seconds left).
/// A child should be able to tell whether it is worth pressing from the
/// corner of their eye while dodging.
class BoostButton extends StatefulWidget {
  const BoostButton({required this.game, super.key});

  final GuzoGame game;

  static const double size = 72;

  @override
  State<BoostButton> createState() => _BoostButtonState();
}

class _BoostButtonState extends State<BoostButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  /// Set when a press is refused, to shake the button instead of doing nothing.
  int _refusedAt = 0;

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _press() {
    if (widget.game.activateBoost()) return;
    // Refusing silently would read as a broken button.
    setState(() => _refusedAt = DateTime.now().millisecondsSinceEpoch);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: widget.game.coins,
      builder: (BuildContext context, int coins, _) {
        return ValueListenableBuilder<double>(
          valueListenable: widget.game.boostRemaining,
          builder: (BuildContext context, double remaining, _) {
            final bool active = remaining > 0;
            final bool ready = !active && coins >= GuzoEconomy.boostCost;

            return _ShakeOnRefusal(
              refusedAt: _refusedAt,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (BuildContext context, Widget? child) {
                  // Only the ready state pulses — a boost you cannot afford
                  // should not keep asking to be pressed.
                  final double scale = ready ? 1 + _pulse.value * 0.06 : 1.0;
                  return Transform.scale(scale: scale, child: child);
                },
                child: _buildButton(
                  coins,
                  remaining,
                  active: active,
                  ready: ready,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildButton(
    int coins,
    double remaining, {
    required bool active,
    required bool ready,
  }) {
    final Color face = active
        ? GuzoColors.boostGlow
        : ready
        ? GuzoColors.secondary
        : GuzoColors.inkSoft;

    return Semantics(
      button: true,
      enabled: ready,
      label: active
          ? '${GuzoStrings.boost} ${remaining.toStringAsFixed(1)} seconds left'
          : ready
          ? GuzoStrings.boost
          : '${GuzoEconomy.boostCost - coins} more coins for a boost',
      child: GestureDetector(
        onTap: _press,
        child: Container(
          width: BoostButton.size,
          height: BoostButton.size,
          decoration: BoxDecoration(
            color: face,
            shape: BoxShape.circle,
            boxShadow: ready || active ? GuzoShadows.card : GuzoShadows.pill,
            border: Border.all(color: GuzoColors.surface, width: 3),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              if (active)
                // A ring that empties as the boost runs down.
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: CircularProgressIndicator(
                      value: remaining / GuzoEconomy.boostDuration,
                      strokeWidth: 4,
                      backgroundColor: GuzoColors.surface.withValues(
                        alpha: 0.3,
                      ),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        GuzoColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const GuzoIcon(GuzoIconAsset.boost, size: 26),
                  const SizedBox(height: 1),
                  Text(
                    active
                        ? '${remaining.toStringAsFixed(1)}s'
                        : ready
                        ? GuzoStrings.boost
                        : '${GuzoEconomy.boostCost - coins}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: GuzoColors.onPrimary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shakes its child briefly whenever [refusedAt] changes.
class _ShakeOnRefusal extends StatefulWidget {
  const _ShakeOnRefusal({required this.refusedAt, required this.child});

  final int refusedAt;
  final Widget child;

  @override
  State<_ShakeOnRefusal> createState() => _ShakeOnRefusalState();
}

class _ShakeOnRefusalState extends State<_ShakeOnRefusal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void didUpdateWidget(_ShakeOnRefusal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refusedAt != oldWidget.refusedAt && widget.refusedAt != 0) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        if (!_controller.isAnimating) return child!;
        // A decaying wobble: three swings that fade out.
        final double offset =
            math.sin(_controller.value * math.pi * 6) *
            6 *
            (1 - _controller.value);
        return Transform.translate(offset: Offset(offset, 0), child: child);
      },
      child: widget.child,
    );
  }
}
