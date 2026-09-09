import '../../utils/constants.dart';
import 'coin.dart';
import 'collectible.dart';
import 'track_chunk.dart';
import 'world_generator.dart';

/// Keeps a sliding window of generated track around the camera.
///
/// Chunks ahead are built before they are visible and chunks behind are
/// dropped, so memory stays flat no matter how far a child runs. Everything is
/// driven by the camera's absolute distance, which is the same value the host
/// will broadcast in Phase 6.
class TrackManager {
  TrackManager({required int seed}) : generator = WorldGenerator(seed: seed);

  final WorldGenerator generator;

  /// Active chunks, always ordered by ascending [TrackChunk.index].
  final List<TrackChunk> _chunks = <TrackChunk>[];

  List<TrackChunk> get chunks => List<TrackChunk>.unmodifiable(_chunks);

  int get seed => generator.seed;

  /// Number of chunks currently held in memory.
  int get chunkCount => _chunks.length;

  /// Builds the initial window. Call once before the first frame.
  void prime() {
    _chunks.clear();
    ensureGenerated(0);
  }

  /// Generates ahead of and prunes behind [cameraZ], in metres.
  void ensureGenerated(double cameraZ) {
    final int centre = (cameraZ / GuzoWorld.chunkLength).floor();
    final int first = centre - GuzoWorld.chunksBehind;
    final int last = centre + GuzoWorld.chunksAhead;

    _chunks.removeWhere((TrackChunk chunk) => chunk.index < first);

    final int firstNeeded = _chunks.isEmpty ? first : _chunks.last.index + 1;
    for (int i = firstNeeded; i <= last; i++) {
      if (i < first) continue;
      _chunks.add(generator.generateChunk(i));
    }
  }

  /// Every obstacle whose world z sits within [halfWindow] metres of [worldZ].
  ///
  /// Used by the collision system; the window is a couple of metres wide, so
  /// this walks only the one or two chunks that can possibly match.
  Iterable<Obstacle> obstaclesNear(double worldZ, double halfWindow) sync* {
    final double min = worldZ - halfWindow;
    final double max = worldZ + halfWindow;

    for (final TrackChunk chunk in _chunks) {
      if (chunk.endZ < min || chunk.startZ > max) continue;
      for (final Obstacle obstacle in chunk.obstacles) {
        if (obstacle.worldZ >= min && obstacle.worldZ <= max) {
          yield obstacle;
        }
      }
    }
  }

  /// Every collectible whose world z sits within [halfWindow] metres of
  /// [worldZ].
  Iterable<Collectible> collectiblesNear(
    double worldZ,
    double halfWindow,
  ) sync* {
    final double min = worldZ - halfWindow;
    final double max = worldZ + halfWindow;

    for (final TrackChunk chunk in _chunks) {
      if (chunk.endZ < min || chunk.startZ > max) continue;
      for (final Collectible collectible in chunk.collectibles) {
        if (collectible.worldZ >= min && collectible.worldZ <= max) {
          yield collectible;
        }
      }
    }
  }

  /// Every coin whose world z sits within [halfWindow] metres of [worldZ].
  Iterable<Coin> coinsNear(double worldZ, double halfWindow) sync* {
    final double min = worldZ - halfWindow;
    final double max = worldZ + halfWindow;

    for (final TrackChunk chunk in _chunks) {
      if (chunk.endZ < min || chunk.startZ > max) continue;
      for (final Coin coin in chunk.coins) {
        if (coin.worldZ >= min && coin.worldZ <= max) yield coin;
      }
    }
  }

  /// Clears every chunk and rebuilds the starting window.
  void reset() => prime();
}
