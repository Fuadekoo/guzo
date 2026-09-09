import '../data/amharic_letters.dart';
import '../data/english_letters.dart';
import '../data/numbers.dart';
import '../utils/constants.dart';
import 'sequence_definition.dart';

/// Every sequence GUZO can play, in one registry.
///
/// Adding a mode means adding an entry here — nothing in the game loop, the
/// world generator or the HUD needs to know it exists.
abstract final class SequenceLibrary {
  /// The mode QUICK PLAY and a fresh multiplayer room start on.
  static SequenceDefinition get defaultSequence => englishAlphabet;

  // --- English ------------------------------------------------------------

  static final SequenceDefinition englishAlphabet = SequenceDefinition(
    id: 'english_az',
    name: 'English Alphabet',
    shortName: 'A–Z',
    category: SequenceCategory.englishLetters,
    description: 'Collect A all the way to Z',
    items: EnglishLetters.uppercase,
  );

  static final SequenceDefinition englishLowercase = SequenceDefinition(
    id: 'english_az_lower',
    name: 'Small Letters',
    shortName: 'a–z',
    category: SequenceCategory.englishLetters,
    description: 'The same race in lowercase',
    items: EnglishLetters.lowercase,
  );

  static final SequenceDefinition englishVowels = SequenceDefinition(
    id: 'english_vowels',
    name: 'Vowels',
    shortName: 'AEIOU',
    category: SequenceCategory.englishLetters,
    description: 'A short first race — five letters',
    items: EnglishLetters.vowels,
  );

  // --- Amharic ------------------------------------------------------------

  static final SequenceDefinition amharicFidel = SequenceDefinition(
    id: 'amharic_fidel',
    name: 'Amharic Fidel',
    shortName: 'ሀ–ፐ',
    category: SequenceCategory.amharicLetters,
    description: 'All 33 base characters, ሀ to ፐ',
    items: AmharicLetters.baseLetters,
    fontFamilyFallback: GuzoFonts.ethiopicFallback,
  );

  static final SequenceDefinition amharicFirstTen = SequenceDefinition(
    id: 'amharic_first_ten',
    name: 'First Ten Fidel',
    shortName: 'ሀ–በ',
    category: SequenceCategory.amharicLetters,
    description: 'A shorter race — ሀ to በ',
    items: AmharicLetters.firstTen,
    fontFamilyFallback: GuzoFonts.ethiopicFallback,
  );

  static final SequenceDefinition amharicHaFamily = SequenceDefinition(
    id: 'amharic_ha_family',
    name: 'The ሀ Family',
    shortName: 'ሀሁሂ',
    category: SequenceCategory.amharicLetters,
    description: 'Every vowel order of ሀ',
    items: AmharicLetters.haFamily,
    fontFamilyFallback: GuzoFonts.ethiopicFallback,
  );

  static final SequenceDefinition amharicLaFamily = SequenceDefinition(
    id: 'amharic_la_family',
    name: 'The ለ Family',
    shortName: 'ለሉሊ',
    category: SequenceCategory.amharicLetters,
    description: 'Every vowel order of ለ',
    items: AmharicLetters.laFamily,
    fontFamilyFallback: GuzoFonts.ethiopicFallback,
  );

  // --- Numbers ------------------------------------------------------------

  static final SequenceDefinition numbersToTen = SequenceDefinition(
    id: 'numbers_1_10',
    name: 'Count to 10',
    shortName: '1–10',
    category: SequenceCategory.numbers,
    description: 'A quick warm-up race',
    items: NumberSequences.range(1, 10),
  );

  static final SequenceDefinition numbersToTwenty = SequenceDefinition(
    id: 'numbers_1_20',
    name: 'Count to 20',
    shortName: '1–20',
    category: SequenceCategory.numbers,
    items: NumberSequences.range(1, 20),
  );

  static final SequenceDefinition numbersToFifty = SequenceDefinition(
    id: 'numbers_1_50',
    name: 'Count to 50',
    shortName: '1–50',
    category: SequenceCategory.numbers,
    items: NumberSequences.range(1, 50),
  );

  static final SequenceDefinition numbersToHundred = SequenceDefinition(
    id: 'numbers_1_100',
    name: 'Count to 100',
    shortName: '1–100',
    category: SequenceCategory.numbers,
    description: 'The long one',
    items: NumberSequences.range(1, 100),
  );

  // --- Challenges ---------------------------------------------------------

  static final SequenceDefinition evenNumbers = SequenceDefinition(
    id: 'numbers_even_20',
    name: 'Even Numbers',
    shortName: '2·4·6',
    category: SequenceCategory.challenge,
    description: '2, 4, 6 … up to 20',
    items: NumberSequences.evens(20),
  );

  static final SequenceDefinition oddNumbers = SequenceDefinition(
    id: 'numbers_odd_19',
    name: 'Odd Numbers',
    shortName: '1·3·5',
    category: SequenceCategory.challenge,
    description: '1, 3, 5 … up to 19',
    items: NumberSequences.odds(19),
  );

  static final SequenceDefinition countdownFromTwenty = SequenceDefinition(
    id: 'numbers_countdown_20',
    name: 'Countdown',
    shortName: '20→1',
    category: SequenceCategory.challenge,
    description: 'Backwards from 20',
    items: NumberSequences.countdown(from: 20),
  );

  static final SequenceDefinition timesTableThree = SequenceDefinition(
    id: 'times_table_3',
    name: 'Three Times Table',
    shortName: '×3',
    category: SequenceCategory.challenge,
    description: '3, 6, 9 … twelve terms',
    items: NumberSequences.multiples(of: 3, count: 12),
  );

  // --- Registry -----------------------------------------------------------

  /// Every sequence, in menu order.
  static List<SequenceDefinition> get all => <SequenceDefinition>[
    englishAlphabet,
    englishLowercase,
    englishVowels,
    amharicFidel,
    amharicFirstTen,
    amharicHaFamily,
    amharicLaFamily,
    numbersToTen,
    numbersToTwenty,
    numbersToFifty,
    numbersToHundred,
    evenNumbers,
    oddNumbers,
    countdownFromTwenty,
    timesTableThree,
  ];

  static List<SequenceDefinition> inCategory(SequenceCategory category) =>
      all.where((SequenceDefinition s) => s.category == category).toList();

  /// Looks up a sequence by its stable id.
  ///
  /// Phase 6 uses this on the receiving end: the host broadcasts an id and
  /// each client resolves it to the same definition.
  static SequenceDefinition? byId(String id) {
    for (final SequenceDefinition sequence in all) {
      if (sequence.id == id) return sequence;
    }
    return null;
  }
}
