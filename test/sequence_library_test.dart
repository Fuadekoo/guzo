import 'package:flutter_test/flutter_test.dart';
import 'package:guzo/data/amharic_letters.dart';
import 'package:guzo/data/english_letters.dart';
import 'package:guzo/data/numbers.dart';
import 'package:guzo/education/sequence_definition.dart';
import 'package:guzo/education/sequence_library.dart';

void main() {
  group('English data', () {
    test('has all 26 letters in order, both cases', () {
      expect(EnglishLetters.uppercase.length, 26);
      expect(EnglishLetters.uppercase.first, 'A');
      expect(EnglishLetters.uppercase.last, 'Z');
      expect(EnglishLetters.lowercase.length, 26);
      expect(EnglishLetters.lowercase.first, 'a');

      for (int i = 0; i < 26; i++) {
        expect(EnglishLetters.uppercase[i], String.fromCharCode(65 + i));
        expect(EnglishLetters.lowercase[i], String.fromCharCode(97 + i));
      }
    });
  });

  group('Amharic data', () {
    // These literals are easy to mangle in an editor or a bad merge and the
    // damage would be invisible in review, so the code points are asserted
    // rather than eyeballed.
    test('has the 33 base characters', () {
      expect(AmharicLetters.baseLetters.length, 33);
      expect(AmharicLetters.baseLetters.first, 'ሀ');
      expect(AmharicLetters.baseLetters.last, 'ፐ');
    });

    test('every character is a single Ethiopic code point', () {
      final List<String> all = <String>[
        ...AmharicLetters.baseLetters,
        ...AmharicLetters.haFamily,
        ...AmharicLetters.laFamily,
      ];

      for (final String letter in all) {
        expect(letter.runes.length, 1, reason: '"$letter" is not one glyph');
        final int code = letter.runes.first;
        expect(
          code,
          inInclusiveRange(
            AmharicLetters.ethiopicBlockStart,
            AmharicLetters.ethiopicBlockEnd,
          ),
          reason: '"$letter" (U+${code.toRadixString(16)}) is not Ethiopic',
        );
      }
    });

    test('the base list starts at U+1200 and has no duplicates', () {
      expect(AmharicLetters.baseLetters.first.runes.first, 0x1200);
      expect(AmharicLetters.baseLetters.toSet().length, 33);
    });

    test('a vowel family is seven consecutive code points', () {
      expect(AmharicLetters.haFamily.length, AmharicLetters.vowelOrders);

      final int base = AmharicLetters.haFamily.first.runes.first;
      for (int i = 0; i < AmharicLetters.haFamily.length; i++) {
        expect(AmharicLetters.haFamily[i].runes.first, base + i);
      }
    });

    test('the ha family matches the sequence given in the brief', () {
      expect(AmharicLetters.haFamily, <String>[
        'ሀ',
        'ሁ',
        'ሂ',
        'ሃ',
        'ሄ',
        'ህ',
        'ሆ',
      ]);
    });

    test('the la family is also seven consecutive code points', () {
      final int base = AmharicLetters.laFamily.first.runes.first;
      expect(base, 0x1208);
      for (int i = 0; i < AmharicLetters.laFamily.length; i++) {
        expect(AmharicLetters.laFamily[i].runes.first, base + i);
      }
    });
  });

  group('Number builders', () {
    test('counts up inclusively', () {
      expect(NumberSequences.range(1, 5), <String>['1', '2', '3', '4', '5']);
      expect(NumberSequences.range(1, 100).length, 100);
      expect(NumberSequences.range(1, 100).last, '100');
    });

    test('counts down when the end is below the start', () {
      expect(NumberSequences.range(5, 1), <String>['5', '4', '3', '2', '1']);
    });

    test('builds even and odd runs', () {
      expect(NumberSequences.evens(10), <String>['2', '4', '6', '8', '10']);
      expect(NumberSequences.odds(9), <String>['1', '3', '5', '7', '9']);
    });

    test('builds a countdown', () {
      expect(NumberSequences.countdown(from: 5).first, '5');
      expect(NumberSequences.countdown(from: 5).last, '1');
      expect(NumberSequences.countdown(from: 100, to: 98), <String>[
        '100',
        '99',
        '98',
      ]);
    });

    test('builds a times table', () {
      expect(NumberSequences.multiples(of: 3, count: 5), <String>[
        '3',
        '6',
        '9',
        '12',
        '15',
      ]);
    });
  });

  group('Library', () {
    test('every sequence is usable and uniquely identified', () {
      final Set<String> ids = <String>{};

      for (final SequenceDefinition sequence in SequenceLibrary.all) {
        expect(
          sequence.items.length,
          greaterThanOrEqualTo(2),
          reason: '${sequence.id} is too short to race',
        );
        expect(sequence.id, isNotEmpty);
        expect(sequence.name, isNotEmpty);
        expect(sequence.shortName, isNotEmpty);
        expect(
          ids.add(sequence.id),
          isTrue,
          reason: 'duplicate id ${sequence.id}',
        );
      }
    });

    test('no sequence repeats an item', () {
      // A repeated item would be ambiguous: collecting it could satisfy either
      // position, and the tracker only ever advances one step.
      for (final SequenceDefinition sequence in SequenceLibrary.all) {
        expect(
          sequence.items.toSet().length,
          sequence.items.length,
          reason: '${sequence.id} repeats an item',
        );
      }
    });

    test('no item is blank', () {
      for (final SequenceDefinition sequence in SequenceLibrary.all) {
        for (final String item in sequence.items) {
          expect(item.trim(), isNotEmpty, reason: '${sequence.id} has a blank');
        }
      }
    });

    test('items stay short enough to draw on a tile', () {
      for (final SequenceDefinition sequence in SequenceLibrary.all) {
        expect(
          sequence.maxItemLength,
          lessThanOrEqualTo(3),
          reason: '${sequence.id} has an item too long for a collectible',
        );
      }
    });

    test('every Amharic mode requests an Ethiopic font', () {
      final List<SequenceDefinition> amharic = SequenceLibrary.inCategory(
        SequenceCategory.amharicLetters,
      );

      expect(amharic, isNotEmpty);
      for (final SequenceDefinition sequence in amharic) {
        expect(
          sequence.fontFamilyFallback,
          isNotNull,
          reason: '${sequence.id} would render as empty boxes',
        );
        expect(sequence.fontFamilyFallback, contains('Noto Sans Ethiopic'));
      }
    });

    test('every category has at least one mode', () {
      for (final SequenceCategory category in SequenceCategory.values) {
        expect(
          SequenceLibrary.inCategory(category),
          isNotEmpty,
          reason: '$category would open an empty screen',
        );
      }
    });

    test('byId round-trips every sequence', () {
      for (final SequenceDefinition sequence in SequenceLibrary.all) {
        expect(SequenceLibrary.byId(sequence.id), same(sequence));
      }
      expect(SequenceLibrary.byId('does_not_exist'), isNull);
    });

    test('the default sequence is in the library', () {
      expect(SequenceLibrary.all, contains(SequenceLibrary.defaultSequence));
    });

    test('the brief\'s three headline modes are present', () {
      expect(SequenceLibrary.englishAlphabet.items.length, 26);
      expect(SequenceLibrary.amharicFidel.items.length, 33);
      expect(SequenceLibrary.numbersToHundred.items.length, 100);
    });
  });
}
