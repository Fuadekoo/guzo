/// The English alphabet, in teaching order.
///
/// Laid out one letter per line, matching the Amharic and number data. It is
/// longer to scroll but every entry is individually visible, which is what
/// makes a missing or duplicated letter obvious at a glance rather than
/// something you have to count to find.
abstract final class EnglishLetters {
  /// A to Z.
  static const List<String> uppercase = <String>[
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
  ];

  /// a to z, for a gentler second pass once uppercase is solid.
  static const List<String> lowercase = <String>[
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
  ];

  /// The five vowels — a short sequence for a first race.
  ///
  /// The sample words are here partly to keep the formatter from folding five
  /// short strings back onto one line, and partly because a future
  /// "A is for Apple" mode will want them.
  static const List<String> vowels = <String>[
    'A', // apple
    'E', // egg
    'I', // igloo
    'O', // orange
    'U', // umbrella
  ];
}
