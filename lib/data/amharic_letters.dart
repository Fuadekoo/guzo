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
/// Every entry is on its own line with its transliteration beside it. The list
/// is long, the glyphs are small, and several pairs differ by a single stroke
/// (ሀ/ሃ, ሠ/ሰ, ጸ/ፀ) — packed onto shared lines a wrong or missing character
/// would be nearly impossible to spot in review.
///
/// Rendering note: no Latin font contains Ethiopic. The app asks for
/// `Noto Sans Ethiopic` first (see `GuzoFonts`), and most Android builds ship
/// it. Bundling the face into `assets/fonts/` removes the doubt — the README
/// there explains how.
abstract final class AmharicLetters {
  /// The 33 base characters in standard order, ሀ through ፐ (U+1200 onward).
  static const List<String> baseLetters = <String>[
    'ሀ', // hä
    'ለ', // lä
    'ሐ', // ḥä
    'መ', // mä
    'ሠ', // śä
    'ረ', // rä
    'ሰ', // sä
    'ሸ', // šä
    'ቀ', // qä
    'በ', // bä
    'ተ', // tä
    'ቸ', // čä
    'ኀ', // ḫä
    'ነ', // nä
    'ኘ', // ñä
    'አ', // ʾä
    'ከ', // kä
    'ኸ', // ḵä
    'ወ', // wä
    'ዐ', // ʿä
    'ዘ', // zä
    'ዠ', // žä
    'የ', // yä
    'ደ', // dä
    'ጀ', // ǧä
    'ገ', // gä
    'ጠ', // ṭä
    'ጨ', // č̣ä
    'ጰ', // ṗä
    'ጸ', // ṣä
    'ፀ', // ḍä
    'ፈ', // fä
    'ፐ', // pä
  ];

  /// The seven vowel orders of ሀ — the example sequence from the brief.
  static const List<String> haFamily = <String>[
    'ሀ', // hä  — 1st order, ግዕዝ
    'ሁ', // hu  — 2nd order, ካዕብ
    'ሂ', // hi  — 3rd order, ሣልስ
    'ሃ', // ha  — 4th order, ራብዕ
    'ሄ', // hé  — 5th order, ኃምስ
    'ህ', // hə  — 6th order, ሳድስ
    'ሆ', // ho  — 7th order, ሳብዕ
  ];

  /// The seven vowel orders of ለ.
  static const List<String> laFamily = <String>[
    'ለ', // lä
    'ሉ', // lu
    'ሊ', // li
    'ላ', // la
    'ሌ', // lé
    'ል', // lə
    'ሎ', // lo
  ];

  /// The names of the seven vowel orders, in order.
  static const List<String> vowelOrderNames = <String>[
    'ግዕዝ', // gəʿəz   — 1st
    'ካዕብ', // kaʿəb   — 2nd
    'ሣልስ', // śaləs   — 3rd
    'ራብዕ', // rabəʿ   — 4th
    'ኃምስ', // ḫaməs   — 5th
    'ሳድስ', // sadəs   — 6th
    'ሳብዕ', // sabəʿ   — 7th
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
