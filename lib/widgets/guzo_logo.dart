import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// The GUZO wordmark plus tagline.
///
/// The title is drawn twice — a dark offset copy behind the fill — to get a
/// sticker-style outline without shipping an image.
class GuzoLogo extends StatelessWidget {
  const GuzoLogo({this.showTagline = true, this.fontSize = 72, super.key});

  final bool showTagline;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = Theme.of(
      context,
    ).textTheme.displayLarge!.copyWith(fontSize: fontSize);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Stack(
          children: <Widget>[
            Text(
              GuzoStrings.appName,
              style: base.copyWith(
                foreground: Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = fontSize * 0.12
                  ..strokeJoin = StrokeJoin.round
                  ..color = GuzoColors.ink,
              ),
            ),
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (Rect bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[GuzoColors.accent, GuzoColors.primary],
              ).createShader(bounds),
              child: Text(GuzoStrings.appName, style: base),
            ),
          ],
        ),
        if (showTagline) ...<Widget>[
          const SizedBox(height: GuzoSizes.spaceSm),
          Text(
            GuzoStrings.tagline,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: GuzoColors.onPrimary,
              letterSpacing: 2,
            ),
          ),
        ],
      ],
    );
  }
}
