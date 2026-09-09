import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../utils/constants.dart';

/// The illustrated icons GUZO ships as artwork.
///
/// GUZO splits its iconography deliberately:
///
/// * **Game content** — coins, boosts, lives, trophies — uses these drawn SVG
///   assets, so a reward looks like an object a child can want.
/// * **UI chrome** — pause, back, settings, navigation — stays on Material
///   icons, which read better as flat controls and cost nothing to ship.
///
/// SVG rather than PNG: one file covers every screen density, the whole set is
/// a few kilobytes, and the artwork stays editable. Everything is bundled in
/// the APK, so nothing here needs a network.
enum GuzoIconAsset {
  coin('coin.svg'),
  boost('boost.svg'),
  heart('heart.svg'),
  distance('distance.svg'),
  trophy('trophy.svg'),
  star('star.svg'),
  runner('runner.svg'),
  shield('shield.svg');

  const GuzoIconAsset(this.fileName);

  final String fileName;

  String get path => '${GuzoAssets.uiDir}$fileName';
}

/// Renders one [GuzoIconAsset] at a given size.
///
/// The placeholder is a same-sized empty box, so the first frame before the
/// SVG is decoded does not shift the layout around it.
class GuzoIcon extends StatelessWidget {
  const GuzoIcon(this.asset, {this.size = 24, super.key});

  final GuzoIconAsset asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset.path,
      width: size,
      height: size,
      placeholderBuilder: (_) => SizedBox.square(dimension: size),
    );
  }
}
