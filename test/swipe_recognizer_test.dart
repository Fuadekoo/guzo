import 'package:flutter_test/flutter_test.dart';
import 'package:guzo/game/input/swipe_recognizer.dart';

void main() {
  late SwipeRecognizer recognizer;

  setUp(() {
    recognizer = SwipeRecognizer(threshold: 28)..start();
  });

  group('Direction', () {
    test('a clear horizontal drag reads as left or right', () {
      expect(recognizer.update(const Offset(40, 0)), SwipeDirection.right);

      recognizer.start();
      expect(recognizer.update(const Offset(-40, 0)), SwipeDirection.left);
    });

    test('a clear vertical drag reads as up or down', () {
      expect(recognizer.update(const Offset(0, -40)), SwipeDirection.up);

      recognizer.start();
      expect(recognizer.update(const Offset(0, 40)), SwipeDirection.down);
    });

    test('a diagonal drag resolves to its dominant axis', () {
      // A small hand rarely swipes straight; the bigger axis should win.
      expect(recognizer.update(const Offset(40, 18)), SwipeDirection.right);

      recognizer.start();
      expect(recognizer.update(const Offset(15, -40)), SwipeDirection.up);
    });
  });

  group('Threshold', () {
    test('a drag below the threshold fires nothing', () {
      expect(recognizer.update(const Offset(10, 0)), isNull);
      expect(recognizer.update(const Offset(8, 0)), isNull);
    });

    test('deltas accumulate until the threshold is crossed', () {
      expect(recognizer.update(const Offset(12, 0)), isNull);
      expect(recognizer.update(const Offset(12, 0)), isNull);
      expect(recognizer.update(const Offset(12, 0)), SwipeDirection.right);
    });

    test('it fires mid-drag rather than waiting for the finger to lift', () {
      // Waiting for the lift would add enough delay to miss an obstacle.
      expect(recognizer.update(const Offset(30, 0)), isNotNull);
    });
  });

  group('One swipe per gesture', () {
    test('further movement in the same drag is ignored', () {
      expect(recognizer.update(const Offset(40, 0)), SwipeDirection.right);
      expect(recognizer.update(const Offset(0, -60)), isNull);
      expect(recognizer.update(const Offset(-90, 0)), isNull);
    });

    test('start() begins a fresh gesture', () {
      recognizer.update(const Offset(40, 0));

      recognizer.start();
      expect(recognizer.update(const Offset(0, -40)), SwipeDirection.up);
    });

    test('end() blocks any late deltas', () {
      recognizer.end();
      expect(recognizer.update(const Offset(90, 0)), isNull);
    });

    test('updates before start() are inert', () {
      final SwipeRecognizer fresh = SwipeRecognizer();
      // Never started, so the latch is closed until a gesture begins.
      expect(fresh.update(const Offset(90, 0)), isNull);

      fresh.start();
      expect(fresh.update(const Offset(90, 0)), SwipeDirection.right);
    });
  });
}
