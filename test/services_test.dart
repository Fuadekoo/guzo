import 'package:flutter_test/flutter_test.dart';
import 'package:guzo/services/audio_service.dart';
import 'package:guzo/services/storage_service.dart';

void main() {
  // Neither the audio nor the preferences plugin exists under `flutter test`.
  // That is the point of these tests: both services have to stay usable when
  // the platform underneath them is missing, because the same thing happens on
  // a real device with a broken audio back end.
  group('AudioService without a platform', () {
    test('is not ready and plays nothing, without throwing', () async {
      final AudioService audio = AudioService.instance;

      await audio.init();

      expect(audio.isReady, isFalse);
      for (final GuzoSound sound in GuzoSound.values) {
        expect(() => audio.play(sound), returnsNormally);
      }
      await expectLater(audio.startMusic(), completes);
      await expectLater(audio.stopMusic(), completes);
    });

    test('remembers the settings it was initialised with', () async {
      final AudioService audio = AudioService.instance;

      await audio.init(sound: false, music: false);
      expect(audio.soundEnabled, isFalse);
      expect(audio.musicEnabled, isFalse);

      await audio.setSoundEnabled(true);
      expect(audio.soundEnabled, isTrue);
    });

    test('every sound maps to a file under assets/sounds', () {
      for (final GuzoSound sound in GuzoSound.values) {
        expect(sound.path, startsWith('sounds/'));
        expect(sound.path, endsWith('.wav'));
      }
    });
  });

  group('SilentGameAudio', () {
    test('accepts everything and does nothing', () async {
      const SilentGameAudio audio = SilentGameAudio();

      expect(() => audio.play(GuzoSound.coin), returnsNormally);
      await expectLater(audio.startMusic(), completes);
      await expectLater(audio.stopMusic(), completes);
    });
  });

  group('StorageService without a platform', () {
    late StorageService storage;

    setUp(() async {
      storage = StorageService.instance;
      await storage.init();
      await storage.clear();
    });

    test('falls back to in-memory values rather than failing', () async {
      expect(storage.isPersistent, isFalse);

      expect(storage.soundEnabled, isTrue);
      await storage.setSoundEnabled(false);
      expect(storage.soundEnabled, isFalse);

      expect(storage.musicEnabled, isTrue);
      await storage.setMusicEnabled(false);
      expect(storage.musicEnabled, isFalse);
    });

    test('has no record for a sequence never finished', () {
      expect(storage.bestFor('english_az'), isNull);
    });

    test('records a first result', () async {
      final bool isRecord = await storage.recordResult(
        sequenceId: 'english_az',
        seconds: 92.5,
        coins: 30,
      );

      expect(isRecord, isTrue);
      expect(storage.bestFor('english_az')?.seconds, 92.5);
      expect(storage.bestFor('english_az')?.coins, 30);
    });

    test('keeps only a faster run', () async {
      await storage.recordResult(
        sequenceId: 'english_az',
        seconds: 90,
        coins: 10,
      );

      expect(
        await storage.recordResult(
          sequenceId: 'english_az',
          seconds: 120,
          coins: 99,
        ),
        isFalse,
        reason: 'a slower run must not overwrite the record',
      );
      expect(storage.bestFor('english_az')?.seconds, 90);
      expect(storage.bestFor('english_az')?.coins, 10);

      expect(
        await storage.recordResult(
          sequenceId: 'english_az',
          seconds: 75,
          coins: 5,
        ),
        isTrue,
      );
      expect(storage.bestFor('english_az')?.seconds, 75);
    });

    test('keeps records for each sequence apart', () async {
      await storage.recordResult(
        sequenceId: 'english_az',
        seconds: 90,
        coins: 10,
      );
      await storage.recordResult(
        sequenceId: 'amharic_fidel',
        seconds: 140,
        coins: 40,
      );

      expect(storage.bestFor('english_az')?.seconds, 90);
      expect(storage.bestFor('amharic_fidel')?.seconds, 140);
      expect(storage.bestFor('numbers_1_10'), isNull);
    });
  });
}
