/// Amharic Fidel (ፊደል).
///
/// The Fidel is a syllabary, not an alphabet: 33 base characters, each written
/// in seven vowel orders, for 231 syllables in total. Amharic children are
/// taught along both axes, so GUZO ships both:
///
/// * [baseLetters] — the 33 first-order (ግዕዝ) characters, the row-by-row
///   reading order used in classrooms.
/// * [haFamily] and [laFamily] — every vowel order of a single base character,
///   which is how a family is drilled.
///
/// Rendering note: no Latin font contains Ethiopic. The app asks for
/// `Noto Sans Ethiopic` first (see `GuzoFonts`), and most Android builds ship
/// it. Bundling the face into `assets/fonts/` removes the doubt — the README
/// there explains how.
abstract final class AmharicLetters {
  /// The 33 base characters in standard order, ሀ through ፐ (U+1200 onward).
  static const List<String> baseLetters = <String>[
    'ሀ',
    'ለ',
    'ሐ',
    'መ',
    'ሠ',
    'ረ',
    'ሰ',
    'ሸ',
    'ቀ',
    'በ',
    'ተ',
    'ቸ',
    'ኀ',
    'ነ',
    'ኘ',
    'አ',
    'ከ',
    'ኸ',
    'ወ',
    'ዐ',
    'ዘ',
    'ዠ',
    'የ',
    'ደ',
    'ጀ',
    'ገ',
    'ጠ',
    'ጨ',
    'ጰ',
    'ጸ',
    'ፀ',
    'ፈ',
    'ፐ',
  ];

  /// The seven vowel orders of ሀ — the example sequence from the brief.
  static const List<String> haFamily = <String>[
    'ሀ',
    'ሁ',
    'ሂ',
    'ሃ',
    'ሄ',
    'ህ',
    'ሆ',
  ];

  /// The seven vowel orders of ለ.
  static const List<String> laFamily = <String>[
    'ለ',
    'ሉ',
    'ሊ',
    'ላ',
    'ሌ',
    'ል',
    'ሎ',
  ];

  /// The first ten base characters — a shorter first race.
  static List<String> get firstTen => baseLetters.sublist(0, 10);

  /// Number of vowel orders per base character.
  static const int vowelOrders = 7;

  /// First and last code points of the Ethiopic Unicode block, used by tests
  /// to prove the literals above did not get mangled by an editor or a commit.
  static const int ethiopicBlockStart = 0x1200;
  static const int ethiopicBlockEnd = 0x137F;
}
