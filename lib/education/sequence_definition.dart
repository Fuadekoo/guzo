/// Broad grouping used to lay out the mode-selection screen.
enum SequenceCategory { englishLetters, amharicLetters, numbers, challenge }

/// One playable educational sequence.
///
/// This is the whole contract between the education side of GUZO and the game
/// side. The gameplay never asks what an item *means* — it only ever compares
/// strings — so English letters, Amharic Fidel, counting, skip-counting and
/// anything added later all run through identical game logic.
///
/// Building a new mode is therefore a data change, not a code change:
///
/// ```dart
/// SequenceDefinition(
///   id: 'times_three',
///   name: 'Three Times Table',
///   shortName: '×3',
///   category: SequenceCategory.challenge,
///   items: NumberSequences.multiples(of: 3, count: 12),
/// )
/// ```
class SequenceDefinition {
  SequenceDefinition({
    required this.id,
    required this.name,
    required this.shortName,
    required this.category,
    required this.items,
    this.description,
    this.fontFamilyFallback,
  }) : assert(items.length >= 2, 'a sequence needs at least two items');

  /// Stable identifier. In multiplayer the host sends this so every client
  /// races the same sequence.
  final String id;

  /// Full name, shown on the mode-selection screen.
  final String name;

  /// Two or three characters for tight spaces, e.g. 'ABC' or '1-20'.
  final String shortName;

  final SequenceCategory category;

  /// The ordered items a player must collect. Each string is drawn verbatim on
  /// the collectible, so it should be short — one glyph, or a small number.
  final List<String> items;

  final String? description;

  /// Fonts to try for this script, most preferred first. Amharic needs an
  /// Ethiopic face that the default Latin font does not contain.
  final List<String>? fontFamilyFallback;

  int get length => items.length;

  /// Longest item, used to scale the glyph so '100' fits the same tile as '7'.
  int get maxItemLength => items.fold(
    1,
    (int longest, String item) => item.length > longest ? item.length : longest,
  );

  @override
  String toString() => 'SequenceDefinition($id, ${items.length} items)';
}
