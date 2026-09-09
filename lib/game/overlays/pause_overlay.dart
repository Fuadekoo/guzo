import 'package:flutter/material.dart';

import '../../utils/constants.dart';
import '../../widgets/guzo_button.dart';

/// Full-screen pause menu shown over a frozen Flame canvas.
///
/// Styled as a raised white card on a scrim, matching the dialogue surfaces in
/// the rest of the app.
class PauseOverlay extends StatelessWidget {
  const PauseOverlay({required this.onResume, required this.onHome, super.key});

  final VoidCallback onResume;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: GuzoColors.scrim,
      child: Center(
        child: Padding(
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
                  const Text('⏸️', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: GuzoSizes.spaceSm),
                  Text(
                    GuzoStrings.paused,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 26,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: GuzoSizes.spaceLg),
                  GuzoButton(
                    label: GuzoStrings.resume,
                    icon: Icons.play_arrow_rounded,
                    onPressed: onResume,
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
