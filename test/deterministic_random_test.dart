import 'package:flutter_test/flutter_test.dart';
import 'package:guzo/utils/deterministic_random.dart';

void main() {
  group('DeterministicRandom', () {
    test('the same seed always produces the same stream', () {
      final DeterministicRandom a = DeterministicRandom(12345);
      final DeterministicRandom b = DeterministicRandom(12345);

      for (int i = 0; i < 200; i++) {
        expect(a.nextUint32(), b.nextUint32());
      }
    });

    test('different seeds diverge', () {
      final DeterministicRandom a = DeterministicRandom(1);
      final DeterministicRandom b = DeterministicRandom(2);

      final List<int> first = List<int>.generate(20, (_) => a.nextUint32());
      final List<int> second = List<int>.generate(20, (_) => b.nextUint32());

      expect(first, isNot(equals(second)));
    });

    test('a zero seed still generates values', () {
      // xorshift is stuck at zero, so the seed must be remapped.
      final DeterministicRandom random = DeterministicRandom(0);
      final Set<int> values = List<int>.generate(
        10,
        (_) => random.nextUint32(),
      ).toSet();

      expect(values.length, greaterThan(1));
    });

    test('nextDouble stays inside [0, 1)', () {
      final DeterministicRandom random = DeterministicRandom(99);

      for (int i = 0; i < 500; i++) {
        final double value = random.nextDouble();
        expect(value, greaterThanOrEqualTo(0));
        expect(value, lessThan(1));
      }
    });

    test('nextInt stays inside [0, max)', () {
      final DeterministicRandom random = DeterministicRandom(7);

      for (int i = 0; i < 500; i++) {
        final int value = random.nextInt(3);
        expect(value, inInclusiveRange(0, 2));
      }
    });

    test('range stays inside its bounds', () {
      final DeterministicRandom random = DeterministicRandom(31);

      for (int i = 0; i < 300; i++) {
        final double value = random.range(-2.5, 4.0);
        expect(value, greaterThanOrEqualTo(-2.5));
        expect(value, lessThan(4.0));
      }
    });

    test('deriveSeed is stable and order independent', () {
      // The multiplayer guarantee: a client that jumps straight to chunk 40
      // derives the same stream as one that walked there.
      expect(
        DeterministicRandom.deriveSeed(555, 40),
        DeterministicRandom.deriveSeed(555, 40),
      );
      expect(
        DeterministicRandom.deriveSeed(555, 40),
        isNot(DeterministicRandom.deriveSeed(555, 41)),
      );
      expect(
        DeterministicRandom.deriveSeed(555, 40),
        isNot(DeterministicRandom.deriveSeed(556, 40)),
      );
    });

    test('nearby seeds and indices do not collide', () {
      final Set<int> derived = <int>{};
      for (int seed = 0; seed < 40; seed++) {
        for (int index = 0; index < 40; index++) {
          derived.add(DeterministicRandom.deriveSeed(seed, index));
        }
      }

      expect(derived.length, 1600);
    });
  });
}
