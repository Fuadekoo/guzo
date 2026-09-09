import 'dart:ui';

import 'package:flame/components.dart';

import '../../utils/constants.dart';
import '../camera/perspective_camera.dart';
import '../painters/collectible_painter.dart';
import '../painters/entity_painter.dart';
import '../painters/glyph_cache.dart';
import '../painters/road_painter.dart';
import '../painters/runner_painter.dart';
import '../guzo_game.dart';
import '../world/collectible.dart';
import '../world/track_chunk.dart';

/// Renders the road, the world and the runner in a single depth-ordered pass.
///
/// Deliberately *not* one Flame component per rock, tree and letter tile. A
/// pseudo-3D scene needs painter's-algorithm ordering, which would mean
/// rewriting every component's priority every frame as objects stream toward
/// the camera — expensive, and it churns Flame's component tree constantly.
/// One render method walking the already-ordered chunk lists is far cheaper
/// and gives exact control over ordering.
///
/// Ordering relies on facts established at generation time: chunks are held in
/// ascending distance order, so iterating them backwards walks the world far
/// to near; scenery is pre-sorted descending within each chunk; obstacles and
/// collectibles are emitted ascending, so both are read backwards and merged.
///
/// Scenery is drawn as a block before the road furniture rather than
/// interleaved by depth. Perspective makes that safe: scenery always sits
/// outside the road edge, and a nearer roadside object is always further from
/// the screen centre than any more distant on-road object.
class TrackView extends Component with HasGameReference<GuzoGame> {
  TrackView() : super(priority: _priority);

  static const int _priority = -50;

  final RoadPainter _road = RoadPainter();
  final EntityPainter _entities = EntityPainter();
  final RunnerPainter _runner = RunnerPainter();
  late final CollectiblePainter _collectibles = CollectiblePainter(
    glyphs: GlyphCache(fontFamilyFallback: game.sequence.fontFamilyFallback),
  );

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;
    _road.resize(size, game.perspective);
  }

  @override
  void onRemove() {
    _collectibles.glyphs.clear();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final PerspectiveCamera camera = game.perspective;
    if (!camera.isReady) return;

    _road.paint(canvas, camera);
    _renderScenery(canvas, camera);

    // Road furniture ahead of the runner, then the runner, then whatever it
    // has already passed — so a rock sweeps past in front of the player.
    _renderTrack(canvas, camera, beyondPlayer: true);
    _runner.paint(canvas, camera, game.player, game.elapsed);
    _renderTrack(canvas, camera, beyondPlayer: false);
  }

  void _renderScenery(Canvas canvas, PerspectiveCamera camera) {
    final List<TrackChunk> chunks = game.track.chunks;

    for (int c = chunks.length - 1; c >= 0; c--) {
      final List<SceneryItem> items = chunks[c].scenery;
      for (int i = 0; i < items.length; i++) {
        _entities.paintScenery(canvas, camera, items[i]);
      }
    }
  }

  /// Draws obstacles and collectibles together, merged by depth.
  ///
  /// Merging matters: a letter tile 50 m out must not paint over a rock 20 m
  /// out. Both lists are already sorted, so this is a two-finger merge walk
  /// per chunk with no sorting and no allocation.
  void _renderTrack(
    Canvas canvas,
    PerspectiveCamera camera, {
    required bool beyondPlayer,
  }) {
    final List<TrackChunk> chunks = game.track.chunks;
    final double travelled = camera.travelled;

    for (int c = chunks.length - 1; c >= 0; c--) {
      final List<Obstacle> obstacles = chunks[c].obstacles;
      final List<Collectible> collectibles = chunks[c].collectibles;

      int o = obstacles.length - 1;
      int k = collectibles.length - 1;

      while (o >= 0 || k >= 0) {
        // Walk both lists from the back, always taking whichever is further
        // away so painting runs strictly far to near.
        final bool takeObstacle =
            k < 0 || (o >= 0 && obstacles[o].worldZ >= collectibles[k].worldZ);

        if (takeObstacle) {
          final Obstacle obstacle = obstacles[o--];
          if (_inPass(camera, obstacle.worldZ, beyondPlayer)) {
            _entities.paintObstacle(canvas, camera, obstacle, travelled);
          }
        } else {
          final Collectible collectible = collectibles[k--];
          if (_inPass(camera, collectible.worldZ, beyondPlayer)) {
            _paintCollectible(canvas, camera, collectible);
          }
        }
      }
    }
  }

  bool _inPass(PerspectiveCamera camera, double worldZ, bool beyondPlayer) =>
      (camera.relativeZ(worldZ) >= GuzoCamera.playerZ) == beyondPlayer;

  void _paintCollectible(
    Canvas canvas,
    PerspectiveCamera camera,
    Collectible collectible,
  ) {
    // A tile already picked up simply stops existing.
    if (game.collection.isConsumed(collectible)) return;

    // The letter a tile shows depends on the player's own progress, so it is
    // resolved here rather than baked in at generation time.
    final String? value = collectible.valueFor(game.tracker);
    if (value == null) return;

    _collectibles.paint(
      canvas,
      camera,
      collectible,
      value,
      game.tracker.isTarget(value),
      game.elapsed,
    );
  }
}
