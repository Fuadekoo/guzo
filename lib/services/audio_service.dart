import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import '../utils/constants.dart';

/// Every sound GUZO can play, and the file behind it.
enum GuzoSound {
  coin('coin.wav'),
  correct('correct.wav'),
  wrong('wrong.wav'),
  jump('jump.wav'),
  slide('slide.wav'),
  hit('hit.wav'),
  boost('boost.wav'),
  smash('smash.wav'),
  complete('complete.wav'),
  countdown('countdown.wav'),
  go('go.wav');

  const GuzoSound(this.fileName);

  final String fileName;

  /// Path relative to the audio cache prefix, which is set to `assets/`.
  String get path => 'sounds/$fileName';
}

/// What the game calls to make a noise.
///
/// An interface rather than a bare singleton so the game can be handed a
/// silent or recording implementation. Tests run with no audio plugin
/// registered, and a game that reached for the real player would crash on
/// every pickup.
abstract interface class GameAudio {
  void play(GuzoSound sound);
  Future<void> startMusic();
  Future<void> stopMusic();
}

/// A [GameAudio] that does nothing. The safe default everywhere.
class SilentGameAudio implements GameAudio {
  const SilentGameAudio();

  @override
  void play(GuzoSound sound) {}

  @override
  Future<void> startMusic() async {}

  @override
  Future<void> stopMusic() async {}
}

/// The real audio player, backed by Flame's audio cache.
///
/// Safe before [init] and safe if [init] fails: every method checks [_ready]
/// first, so a device with no working audio back end simply plays nothing
/// instead of throwing on every coin.
class AudioService implements GameAudio {
  AudioService._();

  static final AudioService instance = AudioService._();

  bool _ready = false;
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _musicPlaying = false;

  /// Time of the last play of each sound, used by the retrigger guard.
  final Map<GuzoSound, DateTime> _lastPlayed = <GuzoSound, DateTime>{};

  bool get isReady => _ready;
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;

  /// Loads every clip into memory up front.
  ///
  /// Pre-loading matters: decoding a file on first play would stutter the
  /// frame a coin is collected on, which is exactly the wrong moment.
  Future<void> init({bool sound = true, bool music = true}) async {
    _soundEnabled = sound;
    _musicEnabled = music;

    try {
      // The brief's folder layout is assets/sounds and assets/music, so the
      // cache is pointed at assets/ rather than Flame's default assets/audio.
      FlameAudio.audioCache.prefix = 'assets/';
      await FlameAudio.audioCache.loadAll(
        GuzoSound.values.map((GuzoSound s) => s.path).toList(),
      );
      _ready = true;
    } catch (error, stack) {
      // Never let audio take the game down with it.
      _ready = false;
      debugPrint('GUZO audio unavailable, continuing silently: $error');
      if (kDebugMode) debugPrintStack(stackTrace: stack);
    }
  }

  @override
  void play(GuzoSound sound) {
    if (!_ready || !_soundEnabled) return;

    // A run of coins can fire several pickups in one frame; overlapping copies
    // of the same clip phase into a harsh click.
    final DateTime now = DateTime.now();
    final DateTime? last = _lastPlayed[sound];
    if (last != null &&
        now.difference(last).inMilliseconds <
            GuzoAudioConfig.retriggerGuard * 1000) {
      return;
    }
    _lastPlayed[sound] = now;

    try {
      FlameAudio.play(sound.path, volume: GuzoAudioConfig.soundVolume);
    } catch (error) {
      debugPrint('GUZO could not play ${sound.name}: $error');
    }
  }

  @override
  Future<void> startMusic() async {
    if (!_ready || !_musicEnabled || _musicPlaying) return;

    try {
      await FlameAudio.bgm.play(
        'music/theme.wav',
        volume: GuzoAudioConfig.musicVolume,
      );
      _musicPlaying = true;
    } catch (error) {
      debugPrint('GUZO could not start music: $error');
    }
  }

  @override
  Future<void> stopMusic() async {
    if (!_musicPlaying) return;
    _musicPlaying = false;

    try {
      await FlameAudio.bgm.stop();
    } catch (error) {
      debugPrint('GUZO could not stop music: $error');
    }
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
  }

  Future<void> setMusicEnabled(bool value) async {
    _musicEnabled = value;
    if (value) {
      await startMusic();
    } else {
      await stopMusic();
    }
  }
}
