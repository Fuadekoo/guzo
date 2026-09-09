/// A tiny xorshift32 pseudo-random generator.
///
/// GUZO deliberately does *not* use `dart:math`'s [Random] for world
/// generation. Its algorithm is an implementation detail of the Dart SDK and
/// differs between the VM and the web compiler, so two players on different
/// builds could generate different tracks from the same seed. Phase 6 makes
/// the host broadcast a seed that every client must reproduce exactly, so the
/// generator has to be part of *our* code, not the SDK's.
///
/// xorshift32 is more than good enough for scattering rocks and trees, and it
/// is fully specified by the three shifts below.
class DeterministicRandom {
  /// Seeds the generator. Zero is remapped because xorshift is stuck at zero.
  DeterministicRandom(int seed)
    : _state = (seed & _mask) == 0 ? _fallbackSeed : seed & _mask;

  static const int _mask = 0xFFFFFFFF;
  static const int _fallbackSeed = 0x9E3779B9;

  int _state;

  /// Advances the state and returns the raw 32-bit value.
  int nextUint32() {
    int x = _state;
    x ^= (x << 13) & _mask;
    x ^= x >> 17;
    x ^= (x << 5) & _mask;
    _state = x & _mask;
    return _state;
  }

  /// A value in `[0, 1)`.
  double nextDouble() => nextUint32() / 4294967296.0;

  /// A value in `[0, max)`. [max] must be positive.
  int nextInt(int max) {
    assert(max > 0, 'max must be positive');
    return nextUint32() % max;
  }

  bool nextBool() => nextUint32() & 1 == 1;

  /// A value in `[min, max)`.
  double range(double min, double max) => min + nextDouble() * (max - min);

  /// True with probability [chance] (`0..1`).
  bool chance(double probability) => nextDouble() < probability;

  /// A uniformly chosen element of [items]. [items] must not be empty.
  T pick<T>(List<T> items) => items[nextInt(items.length)];

  /// Derives an independent stream from a base seed and an index.
  ///
  /// Order independent on purpose: chunk 12 generates the same content whether
  /// it is the first or the hundredth chunk a device builds.
  static int deriveSeed(int baseSeed, int index) {
    int h = (baseSeed ^ (index * 0x9E3779B1)) & _mask;
    h = (h ^ (h >> 16)) & _mask;
    h = (h * 0x85EBCA6B) & _mask;
    h = (h ^ (h >> 13)) & _mask;
    h = (h * 0xC2B2AE35) & _mask;
    return (h ^ (h >> 16)) & _mask;
  }
}
