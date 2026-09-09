import '../../education/sequence_tracker.dart';
import '../../utils/constants.dart';
import '../player/player_controller.dart';
import '../world/collectible.dart';

/// What happened to one collectible this frame.
class CollectionEvent {
  const CollectionEvent({
    required this.collectible,
    required this.value,
    required this.outcome,
  });

  final Collectible collectible;

  /// The text the tile was showing when it was touched.
  final String value;

  final CollectionOutcome outcome;

  bool get isCorrect =>
      outcome == CollectionOutcome.correct ||
      outcome == CollectionOutcome.completed;

  bool get finishedSequence => outcome == CollectionOutcome.completed;
}

/// Picks up educational collectibles the runner touches.
///
/// Separate from [CollisionSystem] on purpose. An obstacle is a physical thing
/// that stops you; a collectible is a question you answer. They have different
/// hitboxes, different consequences and — in Phase 6 — different validation on
/// the host, which re-runs [SequenceTracker.offer] to decide whether a client's
/// claimed pickup really was its next letter.
class CollectionSystem {
  /// Ids already touched this run, so a tile cannot be collected twice.
  ///
  /// Bounded by the number of collectibles actually passed — a few hundred
  /// over a long run — so it never needs pruning. In multiplayer the host
  /// keeps one of these per player.
  final Set<int> _consumed = <int>{};

  /// Depth window that should be searched around the runner, in metres.
  static const double searchWindow = 3.0;

  int get consumedCount => _consumed.length;

  /// Tests [candidates] against the runner and applies any pickups.
  ///
  /// Returns every collectible touched this frame — usually none, sometimes
  /// one, occasionally two when tiles are tightly packed. The caller turns
  /// these into sounds and HUD flashes.
  List<CollectionEvent> collect(
    PlayerController player,
    Iterable<Collectible> candidates,
    SequenceTracker tracker,
    double playerWorldZ,
  ) {
    if (tracker.isComplete) return const <CollectionEvent>[];

    List<CollectionEvent>? events;

    final double playerBottom = player.y;
    final double playerTop = player.y + player.height;

    for (final Collectible collectible in candidates) {
      if (_consumed.contains(collectible.id)) continue;
      if (!_overlaps(
        collectible,
        player,
        playerWorldZ,
        playerBottom,
        playerTop,
      )) {
        continue;
      }

      final String? value = collectible.valueFor(tracker);
      if (value == null) continue;

      _consumed.add(collectible.id);
      final CollectionOutcome outcome = tracker.offer(value);

      (events ??= <CollectionEvent>[]).add(
        CollectionEvent(
          collectible: collectible,
          value: value,
          outcome: outcome,
        ),
      );

      // Stop at the item that finished the sequence; anything after it in the
      // same frame would be offered to an already-complete tracker.
      if (outcome == CollectionOutcome.completed) break;
    }

    return events ?? const <CollectionEvent>[];
  }

  bool _overlaps(
    Collectible collectible,
    PlayerController player,
    double playerWorldZ,
    double playerBottom,
    double playerTop,
  ) {
    // Depth first — it rejects almost everything for the least work.
    final double dz = (collectible.worldZ - playerWorldZ).abs();
    if (dz > GuzoCollectibles.halfDepth + GuzoWorld.playerHalfDepth) {
      return false;
    }

    final double dx = (collectible.x - player.x).abs();
    if (dx > GuzoCollectibles.halfWidth + GuzoWorld.playerHalfWidth) {
      return false;
    }

    // Vertical. A raised tile sits above a standing runner's 1.7 m, so only a
    // jump reaches it — the same geometry rule the obstacles use.
    final double bottom = collectible.height - GuzoCollectibles.halfHeight;
    final double top = collectible.height + GuzoCollectibles.halfHeight;
    return playerBottom < top && playerTop > bottom;
  }

  /// True when this tile has already been picked up and should stop drawing.
  bool isConsumed(Collectible collectible) =>
      _consumed.contains(collectible.id);

  void reset() => _consumed.clear();
}
