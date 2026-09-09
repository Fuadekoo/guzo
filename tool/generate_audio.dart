// Generates GUZO's sound effects and music as 16-bit PCM WAV files.
//
// Run from the project root:
//
//     dart run tool/generate_audio.dart
//
// Why synthesise rather than ship recordings? GUZO is offline-first and every
// asset has to be original. Writing the waveforms means the audio is ours
// outright, has no licence attached, is a few hundred kilobytes in total, and
// can be re-tuned by editing numbers here instead of opening a DAW.
//
// The result is deliberately chiptune: bright, short, readable to a child, and
// the right register to sit under gameplay without masking it. If you later
// commission recorded audio, drop the new files over these with the same
// names and nothing in the app changes.
//
// This is a build-time tool. It is not shipped in the app and imports nothing
// from lib/.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Samples per second. 22.05 kHz halves the file size versus CD rate and is
/// well above what these bright, short sounds need.
const int sampleRate = 22050;

void main() {
  final Directory sounds = Directory('assets/sounds')
    ..createSync(recursive: true);
  final Directory music = Directory('assets/music')
    ..createSync(recursive: true);

  final Map<String, List<double>> effects = <String, List<double>>{
    'coin': _coin(),
    'correct': _correct(),
    'wrong': _wrong(),
    'jump': _jump(),
    'slide': _slide(),
    'hit': _hit(),
    'boost': _boost(),
    'smash': _smash(),
    'complete': _complete(),
    'countdown': _countdownBeep(),
    'go': _goTone(),
  };

  effects.forEach((String name, List<double> samples) {
    final File file = File('${sounds.path}/$name.wav');
    file.writeAsBytesSync(_encodeWav(samples));
    stdout.writeln('${file.path}  ${_kb(file)} KB');
  });

  final File theme = File('${music.path}/theme.wav');
  theme.writeAsBytesSync(_encodeWav(_theme()));
  stdout.writeln('${theme.path}  ${_kb(theme)} KB');
}

String _kb(File file) => (file.lengthSync() / 1024).toStringAsFixed(0);

// ---------------------------------------------------------------------------
// Sound effects
// ---------------------------------------------------------------------------

/// Two rising blips. The classic pickup shape: short enough to fire many times
/// a second without turning into mush.
List<double> _coin() {
  final _Buffer buffer = _Buffer(0.20);
  buffer.tone(at: 0.0, seconds: 0.06, hz: 988, wave: _Wave.square, gain: 0.35);
  buffer.tone(
    at: 0.05,
    seconds: 0.13,
    hz: 1319,
    wave: _Wave.square,
    gain: 0.35,
  );
  return buffer.normalised();
}

/// An ascending major triad — unmistakably "yes".
List<double> _correct() {
  final _Buffer buffer = _Buffer(0.50);
  const List<double> triad = <double>[1047, 1319, 1568]; // C6 E6 G6
  for (int i = 0; i < triad.length; i++) {
    buffer.tone(
      at: i * 0.07,
      seconds: 0.26,
      hz: triad[i],
      wave: _Wave.triangle,
      gain: 0.3,
    );
  }
  // A sparkle an octave up, to lift it above the music.
  buffer.tone(at: 0.20, seconds: 0.22, hz: 2093, wave: _Wave.sine, gain: 0.14);
  return buffer.normalised();
}

/// A soft descending pair. Deliberately gentle: a wrong letter in a children's
/// game should read as "not that one", not as failure.
List<double> _wrong() {
  final _Buffer buffer = _Buffer(0.34);
  buffer.tone(at: 0.0, seconds: 0.14, hz: 392, wave: _Wave.square, gain: 0.22);
  buffer.tone(at: 0.11, seconds: 0.20, hz: 311, wave: _Wave.square, gain: 0.22);
  return buffer.normalised();
}

/// Upward sweep — the sound of leaving the ground.
List<double> _jump() {
  final _Buffer buffer = _Buffer(0.24);
  buffer.sweep(
    at: 0.0,
    seconds: 0.18,
    fromHz: 320,
    toHz: 900,
    wave: _Wave.triangle,
    gain: 0.3,
  );
  return buffer.normalised();
}

/// A short scrape: noise under a falling tone.
List<double> _slide() {
  final _Buffer buffer = _Buffer(0.32);
  buffer.noise(at: 0.0, seconds: 0.26, gain: 0.18, decay: 5);
  buffer.sweep(
    at: 0.0,
    seconds: 0.22,
    fromHz: 420,
    toHz: 160,
    wave: _Wave.sine,
    gain: 0.2,
  );
  return buffer.normalised();
}

/// A dull thud. Low and short, so a stumble registers without startling.
List<double> _hit() {
  final _Buffer buffer = _Buffer(0.36);
  buffer.sweep(
    at: 0.0,
    seconds: 0.24,
    fromHz: 150,
    toHz: 55,
    wave: _Wave.sine,
    gain: 0.42,
  );
  buffer.noise(at: 0.0, seconds: 0.10, gain: 0.16, decay: 14);
  return buffer.normalised();
}

/// A long rising sweep with a shimmer on top — the wind-up of a speed boost.
List<double> _boost() {
  final _Buffer buffer = _Buffer(0.75);
  buffer.sweep(
    at: 0.0,
    seconds: 0.55,
    fromHz: 180,
    toHz: 1500,
    wave: _Wave.saw,
    gain: 0.26,
  );
  buffer.sweep(
    at: 0.08,
    seconds: 0.55,
    fromHz: 360,
    toHz: 3000,
    wave: _Wave.sine,
    gain: 0.12,
  );
  buffer.tone(at: 0.55, seconds: 0.18, hz: 1568, wave: _Wave.square, gain: 0.2);
  return buffer.normalised();
}

/// A bright crack for bursting through an obstacle while boosting.
List<double> _smash() {
  final _Buffer buffer = _Buffer(0.26);
  buffer.noise(at: 0.0, seconds: 0.18, gain: 0.4, decay: 16);
  buffer.tone(at: 0.0, seconds: 0.09, hz: 660, wave: _Wave.square, gain: 0.22);
  return buffer.normalised();
}

/// A short fanfare for finishing the sequence.
List<double> _complete() {
  final _Buffer buffer = _Buffer(1.60);
  const List<double> run = <double>[523, 659, 784, 1047]; // C5 E5 G5 C6
  for (int i = 0; i < run.length; i++) {
    buffer.tone(
      at: i * 0.12,
      seconds: 0.22,
      hz: run[i],
      wave: _Wave.square,
      gain: 0.26,
    );
  }
  // Held major chord to finish on.
  for (final double hz in <double>[523, 659, 784, 1047]) {
    buffer.tone(
      at: 0.52,
      seconds: 0.95,
      hz: hz,
      wave: _Wave.triangle,
      gain: 0.2,
    );
  }
  return buffer.normalised();
}

/// The "3… 2… 1…" tick. Used by the Phase 5 synchronised countdown.
List<double> _countdownBeep() {
  final _Buffer buffer = _Buffer(0.26);
  buffer.tone(at: 0.0, seconds: 0.18, hz: 660, wave: _Wave.square, gain: 0.3);
  return buffer.normalised();
}

/// The "GO!" that follows the countdown — same shape, an octave up and longer.
List<double> _goTone() {
  final _Buffer buffer = _Buffer(0.55);
  buffer.tone(at: 0.0, seconds: 0.42, hz: 1047, wave: _Wave.square, gain: 0.32);
  buffer.tone(
    at: 0.0,
    seconds: 0.42,
    hz: 1568,
    wave: _Wave.triangle,
    gain: 0.18,
  );
  return buffer.normalised();
}

// ---------------------------------------------------------------------------
// Music
// ---------------------------------------------------------------------------

/// An eight-second looping theme: bright, major, and simple enough not to wear
/// out over a long run.
///
/// Four bars of C–G–Am–F at 120 bpm. Square-wave melody over a triangle bass,
/// with a noise hat keeping time. The last note stops just short of the loop
/// point so the seam is inaudible.
List<double> _theme() {
  const double beat = 0.5; // 120 bpm
  const int beats = 16;
  final _Buffer buffer = _Buffer(beats * beat);

  // Bass root of each bar.
  const List<double> roots = <double>[131, 98, 110, 87]; // C3 G2 A2 F2
  for (int bar = 0; bar < 4; bar++) {
    for (int b = 0; b < 4; b++) {
      buffer.tone(
        at: (bar * 4 + b) * beat,
        seconds: beat * 0.9,
        hz: roots[bar],
        wave: _Wave.triangle,
        gain: 0.22,
      );
    }
  }

  // Melody, in eighth notes. Zero means a rest.
  const List<double> melody = <double>[
    523, 659, 784, 659, 523, 0, 587, 659, // bar 1 (C)
    587, 494, 587, 784, 659, 0, 523, 494, // bar 2 (G)
    440, 523, 659, 523, 440, 0, 494, 523, // bar 3 (Am)
    349, 440, 523, 440, 349, 0, 392, 440, // bar 4 (F)
  ];
  for (int i = 0; i < melody.length; i++) {
    if (melody[i] == 0) continue;
    buffer.tone(
      at: i * beat / 2,
      seconds: beat * 0.42,
      hz: melody[i],
      wave: _Wave.square,
      gain: 0.17,
    );
  }

  // Hat on every off-beat, to carry the running tempo.
  for (int i = 0; i < beats * 2; i++) {
    if (i.isEven) continue;
    buffer.noise(at: i * beat / 2, seconds: 0.05, gain: 0.05, decay: 40);
  }

  return buffer.normalised(headroom: 0.72);
}

// ---------------------------------------------------------------------------
// Synthesis
// ---------------------------------------------------------------------------

enum _Wave { sine, square, triangle, saw }

/// A mono sample buffer that sounds are mixed into.
class _Buffer {
  _Buffer(double seconds)
    : samples = List<double>.filled((seconds * sampleRate).round(), 0);

  final List<double> samples;
  final math.Random _random = math.Random(20240909);

  /// Mixes a steady note in, under a percussive attack/decay envelope.
  void tone({
    required double at,
    required double seconds,
    required double hz,
    required _Wave wave,
    required double gain,
  }) {
    _mix(at, seconds, (double t, double progress) {
      return _sample(wave, hz * t) * gain * _envelope(progress);
    });
  }

  /// Mixes a note whose pitch glides from [fromHz] to [toHz].
  void sweep({
    required double at,
    required double seconds,
    required double fromHz,
    required double toHz,
    required _Wave wave,
    required double gain,
  }) {
    // Integrating the frequency ramp keeps the phase continuous; stepping the
    // frequency per sample instead would click audibly.
    _mix(at, seconds, (double t, double progress) {
      final double hz = fromHz + (toHz - fromHz) * progress;
      final double phase = (fromHz + (hz - fromHz) / 2) * t;
      return _sample(wave, phase) * gain * _envelope(progress);
    });
  }

  /// Mixes a burst of white noise with an exponential decay.
  void noise({
    required double at,
    required double seconds,
    required double gain,
    double decay = 8,
  }) {
    _mix(at, seconds, (double t, double progress) {
      return (_random.nextDouble() * 2 - 1) *
          gain *
          math.exp(-decay * progress);
    });
  }

  void _mix(
    double at,
    double seconds,
    double Function(double, double) generate,
  ) {
    final int start = (at * sampleRate).round();
    final int length = (seconds * sampleRate).round();

    for (int i = 0; i < length; i++) {
      final int index = start + i;
      if (index < 0 || index >= samples.length) continue;
      samples[index] += generate(i / sampleRate, i / length);
    }
  }

  /// Fast attack, smooth decay. Keeps every sound percussive and clickless.
  double _envelope(double progress) {
    const double attack = 0.06;
    if (progress < attack) return progress / attack;
    final double rest = (progress - attack) / (1 - attack);
    return math.pow(1 - rest, 1.6).toDouble();
  }

  double _sample(_Wave wave, double phase) {
    final double turns = phase % 1.0;
    switch (wave) {
      case _Wave.sine:
        return math.sin(2 * math.pi * turns);
      case _Wave.square:
        // Slightly narrow pulse: brighter than a straight square, and it cuts
        // through the music better.
        return turns < 0.45 ? 1 : -1;
      case _Wave.triangle:
        return turns < 0.5 ? -1 + 4 * turns : 3 - 4 * turns;
      case _Wave.saw:
        return 2 * turns - 1;
    }
  }

  /// Scales the buffer to [headroom] of full range and fades the very ends, so
  /// nothing clips and no sound starts or stops on a discontinuity.
  List<double> normalised({double headroom = 0.86}) {
    double peak = 0;
    for (final double sample in samples) {
      peak = math.max(peak, sample.abs());
    }
    if (peak == 0) return samples;

    final double scale = headroom / peak;
    final int fade = math.min(
      (0.004 * sampleRate).round(),
      samples.length ~/ 2,
    );

    for (int i = 0; i < samples.length; i++) {
      double value = samples[i] * scale;
      if (i < fade) value *= i / fade;
      final int fromEnd = samples.length - 1 - i;
      if (fromEnd < fade) value *= fromEnd / fade;
      samples[i] = value;
    }
    return samples;
  }
}

/// Wraps samples in a 16-bit mono PCM WAV container.
Uint8List _encodeWav(List<double> samples) {
  const int bitsPerSample = 16;
  const int channels = 1;
  final int dataBytes = samples.length * 2;

  final BytesBuilder builder = BytesBuilder();
  void ascii(String text) => builder.add(text.codeUnits);
  void uint32(int value) => builder.add(
    Uint8List(4)..buffer.asByteData().setUint32(0, value, Endian.little),
  );
  void uint16(int value) => builder.add(
    Uint8List(2)..buffer.asByteData().setUint16(0, value, Endian.little),
  );

  ascii('RIFF');
  uint32(36 + dataBytes);
  ascii('WAVE');

  ascii('fmt ');
  uint32(16); // PCM header size
  uint16(1); // PCM, uncompressed
  uint16(channels);
  uint32(sampleRate);
  uint32(sampleRate * channels * bitsPerSample ~/ 8); // byte rate
  uint16(channels * bitsPerSample ~/ 8); // block align
  uint16(bitsPerSample);

  ascii('data');
  uint32(dataBytes);

  final Uint8List pcm = Uint8List(dataBytes);
  final ByteData view = pcm.buffer.asByteData();
  for (int i = 0; i < samples.length; i++) {
    final int value = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    view.setInt16(i * 2, value, Endian.little);
  }
  builder.add(pcm);

  return builder.toBytes();
}
