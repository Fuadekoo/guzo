import 'package:flutter_test/flutter_test.dart';
import 'package:guzo/education/sequence_definition.dart';
import 'package:guzo/education/sequence_tracker.dart';

SequenceDefinition _abc([List<String>? items]) => SequenceDefinition(
  id: 'test',
  name: 'Test',
  shortName: 'T',
  category: SequenceCategory.englishLetters,
  items: items ?? const <String>['A', 'B', 'C', 'D', 'E'],
);

void main() {
  group('Starting state', () {
    test('begins on the first item with nothing collected', () {
      final SequenceTracker tracker = SequenceTracker(_abc());

      expect(tracker.currentTarget, 'A');
      expect(tracker.collectedCount, 0);
      expect(tracker.totalCount, 5);
      expect(tracker.progress, 0);
      expect(tracker.isComplete, isFalse);
    });
  });

  group('The sequence cannot be skipped', () {
    test('collecting the target advances by exactly one', () {
      final SequenceTracker tracker = SequenceTracker(_abc());

      expect(tracker.offer('A'), CollectionOutcome.correct);
      expect(tracker.currentTarget, 'B');
      expect(tracker.collectedCount, 1);
    });

    test('the brief\'s example: needing C, collecting D does not count', () {
      final SequenceTracker tracker = SequenceTracker(_abc())
        ..offer('A')
        ..offer('B');
      expect(tracker.currentTarget, 'C');

      expect(tracker.offer('D'), CollectionOutcome.wrong);

      // Nothing moved: D is still not collected and C is still wanted.
      expect(tracker.currentTarget, 'C');
      expect(tracker.collectedCount, 2);
    });

    test('an already-collected item does not count again', () {
      final SequenceTracker tracker = SequenceTracker(_abc())..offer('A');

      expect(tracker.offer('A'), CollectionOutcome.wrong);
      expect(tracker.currentTarget, 'B');
      expect(tracker.collectedCount, 1);
    });

    test('an item that is not in the sequence at all is rejected', () {
      final SequenceTracker tracker = SequenceTracker(_abc());

      expect(tracker.offer('Z'), CollectionOutcome.wrong);
      expect(tracker.offer(''), CollectionOutcome.wrong);
      expect(tracker.collectedCount, 0);
    });

    test('a wrong offer can be followed by the right one', () {
      final SequenceTracker tracker = SequenceTracker(_abc());

      tracker.offer('C');
      expect(tracker.offer('A'), CollectionOutcome.correct);
      expect(tracker.currentTarget, 'B');
    });
  });

  group('Completion', () {
    test('the final item reports completion, not just correctness', () {
      final SequenceTracker tracker = SequenceTracker(
        _abc(const <String>['A', 'B']),
      );

      expect(tracker.offer('A'), CollectionOutcome.correct);
      expect(tracker.offer('B'), CollectionOutcome.completed);
      expect(tracker.isComplete, isTrue);
      expect(tracker.currentTarget, isNull);
      expect(tracker.progress, 1);
    });

    test('offers after completion are inert', () {
      final SequenceTracker tracker =
          SequenceTracker(_abc(const <String>['A', 'B']))
            ..offer('A')
            ..offer('B');

      expect(tracker.offer('A'), CollectionOutcome.alreadyComplete);
      expect(tracker.collectedCount, 2);
    });

    test('a full alphabet completes only on the last letter', () {
      final SequenceDefinition alphabet = _abc(<String>[
        for (int c = 65; c <= 90; c++) String.fromCharCode(c),
      ]);
      final SequenceTracker tracker = SequenceTracker(alphabet);

      for (int i = 0; i < 25; i++) {
        expect(tracker.offer(alphabet.items[i]), CollectionOutcome.correct);
      }
      expect(tracker.offer('Z'), CollectionOutcome.completed);
    });
  });

  group('isTarget', () {
    test('is true only for the item due now', () {
      final SequenceTracker tracker = SequenceTracker(_abc());

      expect(tracker.isTarget('A'), isTrue);
      expect(tracker.isTarget('B'), isFalse);

      tracker.offer('A');
      expect(tracker.isTarget('A'), isFalse);
      expect(tracker.isTarget('B'), isTrue);
    });

    test('is false for everything once complete', () {
      final SequenceTracker tracker =
          SequenceTracker(_abc(const <String>['A', 'B']))
            ..offer('A')
            ..offer('B');

      expect(tracker.isTarget('A'), isFalse);
    });
  });

  group('itemAt wrapping', () {
    test('wraps in both directions so a decoy is always a real item', () {
      final SequenceTracker tracker = SequenceTracker(_abc());

      expect(tracker.itemAt(0), 'A');
      expect(tracker.itemAt(5), 'A');
      expect(tracker.itemAt(7), 'C');
      expect(tracker.itemAt(-1), 'E');
    });
  });

  group('HUD window', () {
    test('returns the whole sequence when it is shorter than the window', () {
      final SequenceTracker tracker = SequenceTracker(_abc());

      final List<SequenceSlot> slots = tracker.window(7);
      expect(slots.length, 5);
      expect(slots.first.value, 'A');
    });

    test('slides to keep the target visible in the middle', () {
      final SequenceDefinition alphabet = _abc(<String>[
        for (int c = 65; c <= 90; c++) String.fromCharCode(c),
      ]);
      final SequenceTracker tracker = SequenceTracker(alphabet);
      for (int i = 0; i < 10; i++) {
        tracker.offer(alphabet.items[i]);
      }

      final List<SequenceSlot> slots = tracker.window(7);
      expect(slots.length, 7);
      expect(slots.any((SequenceSlot s) => s.isCurrent), isTrue);
      expect(
        slots.firstWhere((SequenceSlot s) => s.isCurrent).value,
        tracker.currentTarget,
      );
    });

    test('clamps at the start rather than running off the edge', () {
      final SequenceDefinition alphabet = _abc(<String>[
        for (int c = 65; c <= 90; c++) String.fromCharCode(c),
      ]);
      final List<SequenceSlot> slots = SequenceTracker(alphabet).window(7);

      expect(slots.first.value, 'A');
      expect(slots.length, 7);
    });

    test('clamps at the end too', () {
      final SequenceDefinition alphabet = _abc(<String>[
        for (int c = 65; c <= 90; c++) String.fromCharCode(c),
      ]);
      final SequenceTracker tracker = SequenceTracker(alphabet);
      for (final String item in alphabet.items) {
        tracker.offer(item);
      }

      final List<SequenceSlot> slots = tracker.window(7);
      expect(slots.last.value, 'Z');
      expect(slots.every((SequenceSlot s) => s.collected), isTrue);
    });

    test('marks collected, current and upcoming correctly', () {
      final SequenceTracker tracker = SequenceTracker(_abc())..offer('A');

      final List<SequenceSlot> slots = tracker.window(5);
      expect(slots[0].collected, isTrue);
      expect(slots[1].isCurrent, isTrue);
      expect(slots[1].collected, isFalse);
      expect(slots[2].collected, isFalse);
      expect(slots[2].isCurrent, isFalse);
    });
  });

  group('Reset', () {
    test('returns to the first item', () {
      final SequenceTracker tracker = SequenceTracker(_abc())
        ..offer('A')
        ..offer('B');

      tracker.reset();

      expect(tracker.collectedCount, 0);
      expect(tracker.currentTarget, 'A');
      expect(tracker.isComplete, isFalse);
    });
  });
}
