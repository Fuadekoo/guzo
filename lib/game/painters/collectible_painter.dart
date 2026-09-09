import 'dart:math' as math;
import 'dart:ui';

import '../../utils/constants.dart';
import '../camera/perspective_camera.dart';
import '../world/collectible.dart';
import 'glyph_cache.dart';

/// Draws educational collectibles as floating, camera-facing tiles.
///
/// The target and the decoys are separated on three cues at once — warm versus
/// cool colour, a glow, and an orbiting ring — because a child scanning a busy
/// road at speed should not have to *read* the letter to know which tile is
/// theirs. Reading it confirms the choice; the colour makes it.
class CollectiblePainter {
  CollectiblePainter({GlyphCache? glyphs}) : glyphs = glyphs ?? GlyphCache();

  GlyphCache glyphs;

  final Paint _fill = Paint();
  final Paint _stroke = Paint()..style = PaintingStyle.stroke;
  final Paint _shadow = Paint()..color = GuzoColors.ink.withValues(alpha: 0.14);

  /// Tile half-size in metres.
  static const double _tileRadius = 0.42;

  /// Dots in a target's orbiting ring.
  static const int _ringDots = 8;

  void paint(
    Canvas canvas,
    PerspectiveCamera camera,
    Collectible collectible,
    String value,
    bool isTarget,
    double elapsed,
  ) {
    final double z = camera.relativeZ(collectible.worldZ);
    if (!camera.isVisible(z)) return;

    final double scale = camera.scaleAt(z);
    final double radius = _tileRadius * scale;
    // Skip tiles that have shrunk past legibility — they are pure noise at
    // that size, and the glyph would not resolve anyway.
    if (radius < 3) return;

    // Each tile bobs on its own phase, derived from its id, so a line of them
    // ripples instead of pulsing as one block.
    final double phase = (collectible.id % 32) / 32 * 2 * math.pi;
    final double bob =
        math.sin(
          elapsed * 2 * math.pi * GuzoCollectibles.bobCyclesPerSecond + phase,
        ) *
        GuzoCollectibles.bobHeight;

    final Offset centre = camera.project(
      collectible.x,
      collectible.height + bob,
      z,
    );

    _paintGroundShadow(canvas, camera, collectible, z, scale);

    if (isTarget) {
      _paintGlow(canvas, centre, radius);
      _paintRing(canvas, centre, radius, elapsed);
    }

    _paintTile(canvas, centre, radius, isTarget);

    glyphs.draw(
      canvas,
      value,
      isTarget ? GuzoColors.targetGlyph : GuzoColors.decoyGlyph,
      centre,
      radius * 1.35,
      radius * 1.15,
    );
  }

  /// A shadow directly under the tile, which is what tells a child whether it
  /// is at running height or needs a jump.
  void _paintGroundShadow(
    Canvas canvas,
    PerspectiveCamera camera,
    Collectible collectible,
    double z,
    double scale,
  ) {
    canvas.drawOval(
      Rect.fromCenter(
        center: camera.project(collectible.x, 0, z),
        width: 0.5 * scale,
        height: 0.16 * scale,
      ),
      _shadow,
    );
  }

  void _paintGlow(Canvas canvas, Offset centre, double radius) {
    _fill.color = GuzoColors.targetGlow.withValues(alpha: 0.32);
    canvas.drawCircle(centre, radius * 1.85, _fill);
    _fill.color = GuzoColors.targetGlow.withValues(alpha: 0.45);
    canvas.drawCircle(centre, radius * 1.4, _fill);
  }

  /// Dots orbiting the target tile. Cheaper than a rotating stroked ring and
  /// reads more clearly at small sizes.
  void _paintRing(Canvas canvas, Offset centre, double radius, double elapsed) {
    final double turn =
        elapsed * GuzoCollectibles.ringTurnsPerSecond * 2 * math.pi;
    final double orbit = radius * 1.55;
    final double dotRadius = math.max(radius * 0.11, 1);

    _fill.color = GuzoColors.targetTileEdge;
    for (int i = 0; i < _ringDots; i++) {
      final double angle = turn + i * 2 * math.pi / _ringDots;
      canvas.drawCircle(
        centre.translate(math.cos(angle) * orbit, math.sin(angle) * orbit),
        dotRadius,
        _fill,
      );
    }
  }

  void _paintTile(Canvas canvas, Offset centre, double radius, bool isTarget) {
    final RRect tile = RRect.fromRectAndRadius(
      Rect.fromCenter(center: centre, width: radius * 2, height: radius * 2),
      Radius.circular(radius * 0.34),
    );

    _fill.color = isTarget ? GuzoColors.targetTile : GuzoColors.decoyTile;
    canvas.drawRRect(tile, _fill);

    _stroke
      ..color = isTarget ? GuzoColors.targetTileEdge : GuzoColors.decoyTileEdge
      ..strokeWidth = math.max(radius * 0.12, 1);
    canvas.drawRRect(tile, _stroke);
  }
}
