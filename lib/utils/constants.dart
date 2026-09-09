import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Static text shown across the app.
///
/// Kept in one place so a future localisation layer only has to replace this
/// class rather than hunt through widgets.
abstract final class GuzoStrings {
  static const String appName = 'GUZO';
  static const String tagline = 'Learn • Run • Compete';

  static const String quickPlay = 'QUICK PLAY';
  static const String multiplayer = 'MULTIPLAYER';
  static const String educationalModes = 'EDUCATIONAL MODES';
  static const String settings = 'SETTINGS';

  static const String resume = 'RESUME';
  static const String home = 'HOME';
  static const String paused = 'PAUSED';

  // Home screen
  static const String greeting = 'Ready to learn and have fun?';
  static const String chooseCategory = 'Choose a Category';
  static const String yourProgress = 'Your Progress';
  static const String bestDistance = 'Best Distance';

  // Categories
  static const String englishLetters = 'Letters';
  static const String amharicLetters = 'Amharic';
  static const String numbers = 'Numbers';
  static const String playTogether = 'Play Together';
  static const String challenges = 'Challenges';

  // Run completion
  static const String sequenceComplete = 'SEQUENCE COMPLETE!';
  static const String playAgain = 'PLAY AGAIN';
  static const String statTime = 'Time';
  static const String statDistance = 'Distance';
  static const String statCollected = 'Collected';

  // Mode selection
  static const String selectMode = 'Select Mode';
  static const String chooseChallenge = 'Choose a challenge';

  // Bottom navigation
  static const String navHome = 'Home';
  static const String navPlay = 'Play';
  static const String navAwards = 'Awards';
  static const String navProfile = 'Profile';
}

/// The GUZO palette: a bright highland-trail adventure look.
///
/// Warm sun + green highlands + a dirt running trail. Deliberately distinct
/// from the dark jungle palette of other endless runners.
abstract final class GuzoColors {
  // Brand
  static const Color primary = Color(0xFFFF8A3D); // sunset orange
  static const Color primaryDark = Color(0xFFE86C1A);
  static const Color secondary = Color(0xFF00C2A8); // teal
  static const Color secondaryDark = Color(0xFF009C88);
  static const Color accent = Color(0xFFFFD23F); // coin yellow
  static const Color danger = Color(0xFFE9484B);

  // Text
  static const Color ink = Color(0xFF12294A); // deep navy
  static const Color inkSoft = Color(0xFF5A7091);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Surfaces
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF2F6FB);
  static const Color scrim = Color(0xCC12294A);

  /// Fill behind the selected item in the bottom navigation bar.
  static const Color navActive = Color(0xFF5B4BD6);

  /// Home screen backdrop, top to bottom.
  static const Color homeTop = Color(0xFF6FD3FF);
  static const Color homeBottom = Color(0xFFE8F6FF);

  // Sky
  static const Color skyTop = Color(0xFF35B6F0);
  static const Color skyBottom = Color(0xFFB9ECFF);
  static const Color sun = Color(0xFFFFE27A);
  static const Color cloud = Color(0xFFFFFFFF);
  static const Color hillFar = Color(0xFF7FC98A);
  static const Color hillNear = Color(0xFF4CAF62);

  // Ground beside the road
  static const Color grass = Color(0xFF4CC46A);
  static const Color grassFar = Color(0xFF77D48D);

  // Road
  static const Color road = Color(0xFFD2A26B);
  static const Color roadBand = Color(0xFFC3915B);
  static const Color roadEdge = Color(0xFF8F6440);
  static const Color laneDash = Color(0xFFF6E6CB);

  // Obstacles — each has a lit top face and a shaded front face so the
  // projected boxes read as solid objects.
  static const Color rockTop = Color(0xFFA9AFB8);
  static const Color rockFront = Color(0xFF7E858F);
  static const Color logTop = Color(0xFFB07A44);
  static const Color logFront = Color(0xFF8A5C30);
  static const Color barrierTop = Color(0xFFFF6B5B);
  static const Color barrierFront = Color(0xFFD24537);
  static const Color hurdleTop = Color(0xFFFFC24A);
  static const Color hurdleFront = Color(0xFFDF9B1E);
  static const Color postTop = Color(0xFFE9EDF2);
  static const Color postFront = Color(0xFFB9C1CC);
  static const Color holeFill = Color(0xFF3A2B1E);
  static const Color holeRim = Color(0xFF6B4F36);

  // Scenery
  static const Color trunk = Color(0xFF8A5C30);
  static const Color canopy = Color(0xFF39A85B);
  static const Color canopyLight = Color(0xFF56C878);
  static const Color bush = Color(0xFF3FBF6B);
  static const Color boulder = Color(0xFF98A0AA);

  // Educational collectibles. The target is warm and glowing; decoys are cool
  // and flat, so a child reads "mine" versus "not mine" by colour temperature
  // before they have even read the letter.
  static const Color targetTile = Color(0xFFFFD23F);
  static const Color targetTileEdge = Color(0xFFE8A317);
  static const Color targetGlow = Color(0xFFFFF3C4);
  static const Color targetGlyph = Color(0xFF5A3B00);

  static const Color decoyTile = Color(0xFFDCE6F2);
  static const Color decoyTileEdge = Color(0xFFA9BDD4);
  static const Color decoyGlyph = Color(0xFF5A7091);

  static const Color correctFlash = Color(0xFF4CC96A);
  static const Color wrongFlash = Color(0xFFE9484B);

  // Runner
  static const Color runnerSkin = Color(0xFF8D5524);
  static const Color runnerSkinDark = Color(0xFF6F421C);
  static const Color runnerShirt = Color(0xFF2E7BE5);
  static const Color runnerShirtDark = Color(0xFF1F5DB8);
  static const Color runnerShorts = Color(0xFFFF8A3D);
  static const Color runnerShoe = Color(0xFFFFFFFF);
  static const Color runnerHair = Color(0xFF241A12);
}

/// Spacing, radii and other layout numbers.
///
/// Sizes are generous on purpose: GUZO is played by children on small phones.
abstract final class GuzoSizes {
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 40;

  static const double radiusSm = 12;
  static const double radiusMd = 20;
  static const double radiusLg = 28;
  static const double radiusPill = 999;

  static const double buttonHeight = 64;
  static const double buttonMaxWidth = 460;
  static const double iconButtonSize = 46;
  static const double navBarHeight = 68;
  static const double tileAspectRatio = 1.15;
}

/// Colours for the educational category tiles on the home screen.
///
/// Each tile carries a face colour and the deeper shade used for its shadow
/// slab, which is what gives the cards their moulded, pressable look.
abstract final class GuzoCategoryColors {
  static const Color letters = Color(0xFFFFC93C);
  static const Color lettersDark = Color(0xFFE0A413);
  static const Color numbers = Color(0xFF4CC96A);
  static const Color numbersDark = Color(0xFF31A44C);
  static const Color amharic = Color(0xFF9B6BE8);
  static const Color amharicDark = Color(0xFF7A49CC);
  static const Color multiplayer = Color(0xFF3FA9F5);
  static const Color multiplayerDark = Color(0xFF1E86D0);
}

/// Soft drop shadows shared by every raised surface.
abstract final class GuzoShadows {
  /// Standard white card lifted off a coloured background.
  static const List<BoxShadow> card = <BoxShadow>[
    BoxShadow(color: Color(0x1A12294A), blurRadius: 18, offset: Offset(0, 8)),
  ];

  /// Tighter shadow for pills and small chips.
  static const List<BoxShadow> pill = <BoxShadow>[
    BoxShadow(color: Color(0x1412294A), blurRadius: 10, offset: Offset(0, 4)),
  ];

  /// The bottom navigation bar floats above everything else.
  static const List<BoxShadow> navBar = <BoxShadow>[
    BoxShadow(color: Color(0x2212294A), blurRadius: 24, offset: Offset(0, 10)),
  ];
}

/// Simulation rules, in **metres and seconds**.
///
/// The whole simulation is unit-based rather than pixel-based. That keeps the
/// rules identical on every screen size — a requirement for the
/// host-authoritative multiplayer of Phase 6, where the host validates a
/// client's position without knowing its resolution.
abstract final class GuzoWorld {
  // --- Track geometry -----------------------------------------------------
  /// Lane indices run -1, 0, 1.
  static const int laneCount = 3;
  static const double laneWidth = 2.0;

  /// Half the drivable road width. Slightly wider than the outer lane centres
  /// so the runner never appears to hang off the edge.
  static const double roadHalfWidth = 3.0;

  /// World x position of a lane index.
  static double laneToX(int lane) => lane * laneWidth;

  // --- Speed --------------------------------------------------------------
  static const double startSpeed = 9.0; // m/s
  static const double maxSpeed = 16.0; // m/s
  static const double speedRampPerMetre = 0.006;

  /// Forward speed after running [distance] metres.
  ///
  /// A pure function of distance, so the world generator can ask "how fast
  /// will the player be here?" while building track far ahead of the runner.
  static double speedAt(double distance) => math.min(
    maxSpeed,
    startSpeed + math.max(0, distance) * speedRampPerMetre,
  );

  // --- Player -------------------------------------------------------------
  static const double playerHeight = 1.7;
  static const double slideHeight = 0.8;
  static const double playerHalfWidth = 0.45;
  static const double playerHalfDepth = 0.4;

  /// Seconds to move fully from one lane to the next.
  static const double laneChangeDuration = 0.16;
  static const double gravity = -20.0; // m/s^2
  static const double jumpVelocity = 7.5; // 0.75 s airtime, 1.4 m peak
  static const double diveVelocity = -14.0;
  static const double slideDuration = 0.65;

  /// Highest point of a running jump, derived from the launch velocity.
  ///
  /// The obstacle table uses this to decide which boxes are jumpable, so
  /// retuning [jumpVelocity] automatically retunes the difficulty rather than
  /// silently making some obstacles impossible.
  static double get jumpPeakHeight =>
      (jumpVelocity * jumpVelocity) / (-2 * gravity);

  /// Window in which a jump or slide pressed slightly too early still counts.
  static const double inputBufferDuration = 0.18;

  // --- Collision response -------------------------------------------------
  // GUZO never kills the player: a hit costs speed and a stagger, nothing more.
  static const double stumbleDuration = 0.7;
  static const double stumbleSpeedFactor = 0.45;
  static const double invulnerableDuration = 1.1;

  // --- Streaming ----------------------------------------------------------
  /// Length of one generated chunk.
  ///
  /// Long relative to the obstacle spacing on purpose. Each chunk holds its
  /// first row back by one reaction gap so it cannot crowd the previous
  /// chunk's last row (see `WorldGenerator`), and a long chunk keeps that
  /// quiet stretch a small fraction of the whole rather than an audible
  /// rhythm every few seconds.
  static const double chunkLength = 120.0;

  /// Chunks kept generated ahead of the camera. Two covers the 95 m far plane
  /// with a full chunk to spare.
  static const int chunksAhead = 2;

  /// Chunks kept behind the camera before being dropped.
  static const int chunksBehind = 1;

  static const double nearPlane = 1.0;
  static const double farPlane = 95.0;

  // --- Difficulty ---------------------------------------------------------
  /// No obstacles at all for the first stretch, so a child can settle in.
  static const double warmUpDistance = 60.0;

  /// Below this distance only ever one lane is blocked at a time.
  static const double singleLaneUntil = 180.0;

  /// Minimum gap between obstacle rows, expressed as reaction time.
  ///
  /// Multiplied by the local speed, so the gap in metres grows as the run gets
  /// faster and the time a child has to react stays constant.
  static const double minReactionSeconds = 1.15;
  static const double maxExtraGapSeconds = 1.1;
}

/// Pseudo-3D camera settings.
///
/// Tuned for a portrait phone, the orientation this genre is played in: the
/// road fans off both sides of the screen near the camera and converges around
/// 15 m out, and the runner stands about a fifth of the screen tall.
abstract final class GuzoCamera {
  /// Eye height above the road, in metres.
  static const double height = 2.6;

  /// How far ahead of the camera the runner is pinned, in metres.
  static const double playerZ = 5.0;

  /// Focal length as a multiple of screen height.
  static const double focalFactor = 0.62;

  /// Upper bound on the focal length, as a multiple of screen width. Stops an
  /// unusually tall or narrow screen zooming in so far that the road fills
  /// everything.
  static const double focalWidthCap = 1.6;

  /// Horizon position as a fraction of screen height.
  static const double horizonFactor = 0.28;

  /// How much of the runner's lane offset the camera follows (0 = fixed).
  static const double lateralFollow = 0.35;

  /// Seconds for the camera to catch up with the runner sideways.
  static const double lateralSmoothing = 0.12;
}

/// Purely cosmetic numbers: animation rates and backdrop parallax.
abstract final class GuzoVisuals {
  /// Full run cycles (two steps) per metre travelled.
  static const double runCyclesPerMetre = 0.32;

  /// Backdrop drift in pixels per metre travelled.
  static const double cloudParallax = 0.55;
  static const double hillFarParallax = 1.4;
  static const double hillNearParallax = 3.6;

  /// How far the backdrop slides sideways per metre of camera offset.
  static const double backdropLateralShift = 8.0;

  /// Road bands alternate every this many metres.
  static const double roadBandLength = 4.0;

  /// A projected slice is skipped once it is thinner than this many pixels.
  static const double minBandPixels = 1.2;
}

/// Font families requested for non-Latin scripts.
///
/// GUZO ships no font of its own — the default Latin face covers English and
/// digits. Amharic does not: no Latin font contains the Ethiopic block, so a
/// device without an Ethiopic face renders Fidel as empty boxes.
///
/// The fallback list below asks for the common system faces by name. Most
/// Android builds carry Noto Sans Ethiopic and will resolve one of them. To
/// remove the doubt entirely, drop a font file into `assets/fonts/` and
/// register it in `pubspec.yaml` — `assets/fonts/README.md` has the steps.
abstract final class GuzoFonts {
  static const List<String> ethiopicFallback = <String>[
    'Noto Sans Ethiopic',
    'Noto Serif Ethiopic',
    'Abyssinica SIL',
    'Nyala',
  ];
}

/// Educational collectibles: geometry and pacing.
abstract final class GuzoCollectibles {
  /// Half-extents of a collectible's pickup box, in metres.
  static const double halfWidth = 0.45;
  static const double halfHeight = 0.45;
  static const double halfDepth = 0.45;

  /// Centre height of a low tile — reachable while running or sliding.
  static const double lowHeight = 1.0;

  /// Centre height of a raised tile. Its box spans 1.80–2.70 m, above a
  /// standing runner's 1.7 m, so it must be jumped for.
  static const double highHeight = 2.25;

  /// A moment of plain running before the first pickup, so the first thing a
  /// child meets is not a decision.
  static const double startDistance = 18.0;

  /// Items in one group, and the gap between them.
  static const int minGroupSize = 3;
  static const int maxGroupSize = 5;
  static const double itemSpacing = 3.0;

  /// Gap between the end of one group and the start of the next.
  static const double minGroupGap = 14.0;
  static const double maxGroupGap = 24.0;

  /// Clearance kept between a collectible and any obstacle row, so a pickup
  /// never sits where the runner is busy dodging.
  static const double obstacleClearance = 6.0;

  /// Share of groups that contain the player's current target. The rest are
  /// all decoys, which is what makes a missed target cost something.
  static const double targetGroupChance = 0.72;

  /// A group never holds more than one target, so one group advances the
  /// sequence by at most one item.
  static const int maxTargetsPerGroup = 1;

  /// Bob animation of a floating tile.
  static const double bobHeight = 0.12;
  static const double bobCyclesPerSecond = 0.8;

  /// Spin rate of the target's highlight ring, in turns per second.
  static const double ringTurnsPerSecond = 0.35;
}

/// Asset paths.
///
/// Declared up front so later phases reference constants instead of raw
/// strings. Folders are created and registered in `pubspec.yaml`.
abstract final class GuzoAssets {
  static const String imagesRoot = 'assets/images/';
  static const String playersDir = '${imagesRoot}players/';
  static const String obstaclesDir = '${imagesRoot}obstacles/';
  static const String collectiblesDir = '${imagesRoot}collectibles/';
  static const String coinsDir = '${imagesRoot}coins/';
  static const String backgroundsDir = '${imagesRoot}backgrounds/';
  static const String uiDir = '${imagesRoot}ui/';

  static const String soundsDir = 'assets/sounds/';
  static const String musicDir = 'assets/music/';
}

/// Names of the Flutter widget overlays mounted on top of the Flame canvas.
abstract final class GuzoOverlays {
  static const String hud = 'hud';
  static const String pause = 'pause';
  static const String complete = 'complete';
}
