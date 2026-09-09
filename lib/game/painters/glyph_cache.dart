import 'dart:math' as math;
import 'dart:ui';

/// Lays out and caches the text drawn on collectibles.
///
/// Text is by far the most expensive thing GUZO draws in the world: laying out
/// a glyph means shaping it through the font every time. With up to a dozen
/// tiles on screen at 60 fps that would be hundreds of layouts a second.
///
/// So every distinct glyph is laid out **once** at a fixed reference size and
/// kept. Drawing it at any depth is then just a canvas scale — no shaping, no
/// allocation. The cache is bounded by the alphabet in play: 26 for English,
/// 33 for Fidel, 100 for counting to a hundred, times the two colour roles.
class GlyphCache {
  GlyphCache({this.fontFamilyFallback});

  /// Fonts to try, most preferred first. Amharic needs an Ethiopic face.
  final List<String>? fontFamilyFallback;

  /// Reference size everything is laid out at, then scaled from.
  static const double referenceFontSize = 64;

  final Map<String, Paragraph> _cache = <String, Paragraph>{};

  int get size => _cache.length;

  Paragraph _paragraphFor(String text, Color color) {
    final String key = '$text|${color.toARGB32()}';
    final Paragraph? cached = _cache[key];
    if (cached != null) return cached;

    final ParagraphBuilder builder =
        ParagraphBuilder(
            ParagraphStyle(
              fontSize: referenceFontSize,
              fontWeight: FontWeight.w900,
              textAlign: TextAlign.center,
              // ParagraphStyle takes a single family; the full fallback list goes on
              // the pushed TextStyle below, which is what actually shapes the glyph.
              fontFamily: fontFamilyFallback?.first,
            ),
          )
          ..pushStyle(
            TextStyle(
              color: color,
              fontSize: referenceFontSize,
              fontWeight: FontWeight.w900,
              fontFamilyFallback: fontFamilyFallback,
            ),
          )
          ..addText(text);

    final Paragraph paragraph = builder.build()
      // Wide enough for the longest item a sequence can hold ('100').
      ..layout(const ParagraphConstraints(width: referenceFontSize * 4));

    _cache[key] = paragraph;
    return paragraph;
  }

  /// Draws [text] centred on [centre], fitted inside [maxWidth] × [maxHeight].
  ///
  /// Fits on whichever axis binds, so '100' shrinks to the same tile that
  /// comfortably holds '7' instead of spilling out of it.
  void draw(
    Canvas canvas,
    String text,
    Color color,
    Offset centre,
    double maxWidth,
    double maxHeight,
  ) {
    if (maxWidth <= 0 || maxHeight <= 0) return;

    final Paragraph paragraph = _paragraphFor(text, color);
    final double inkWidth = math.max(paragraph.longestLine, 1);
    final double inkHeight = math.max(paragraph.height, 1);

    final double scale = math.min(maxWidth / inkWidth, maxHeight / inkHeight);
    if (scale <= 0 || !scale.isFinite) return;

    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(scale);
    // The paragraph is centre-aligned inside its layout width, so centring
    // means offsetting by that width, not by the ink width.
    canvas.translate(-paragraph.width / 2, -inkHeight / 2);
    canvas.drawParagraph(paragraph, Offset.zero);
    canvas.restore();
  }

  /// Drops every cached layout. Called when the sequence changes, so a switch
  /// from Fidel to digits does not keep the old alphabet resident.
  void clear() {
    for (final Paragraph paragraph in _cache.values) {
      paragraph.dispose();
    }
    _cache.clear();
  }
}
