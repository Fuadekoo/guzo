import 'package:guzo/services/audio_service.dart';

/// A [GameAudio] that records what it was asked to play.
///
/// Sound is a real part of the game's feedback loop — a coin that makes no
/// noise is a bug a player would notice immediately — so the tests assert on
/// it rather than trusting it. This also keeps the audio plugin, which does
/// not exist under `flutter test`, out of the way entirely.
class RecordingGameAudio implements GameAudio {
  final List<GuzoSound> played = <GuzoSound>[];
  bool musicPlaying = false;

  @override
  void play(GuzoSound sound) => played.add(sound);

  @override
  Future<void> startMusic() async => musicPlaying = true;

  @override
  Future<void> stopMusic() async => musicPlaying = false;

  bool didPlay(GuzoSound sound) => played.contains(sound);

  int countOf(GuzoSound sound) =>
      played.where((GuzoSound s) => s == sound).length;

  void clear() => played.clear();
}
