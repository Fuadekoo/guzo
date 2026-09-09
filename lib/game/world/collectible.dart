import '../../education/sequence_tracker.dart';
import '../../utils/constants.dart';

/// What a collectible shows, expressed relative to the player's own progress.
///
/// The world is generated from a shared seed, but every player is at a
/// different point in the sequence — one needs C while another needs H. So the
/// generator cannot bake a letter into a tile. It stores a *role* instead, and
/// the letter is resolved per player at the moment it is drawn or picked up.
///
/// That is what lets four phones race an identical track while each child
/// works through their own alphabet.
enum CollectibleRole {
  /// Shows whatever the player needs right now. Collecting it advances them.
  target,

  /// Shows the item immediately *after* the target — the classic trap from
  /// the brief: the target is C, so this tile reads D and must be ignored.
  ahead,

  /// Shows some other item from the sequence.
  decoy,
}

/// One educational pickup on the track.
class Collectible {
  const Collectible({
    required this.id,
    required this.worldZ,
    required this.lane,
    required this.role,
    required this.height,
    this.decoySeed = 0,
  });

  /// Stable identifier, unique across the run. Phase 6 refers to a pickup by
  /// this id when a client tells the host what it collected.
  final int id;

  /// Absolute distance from the start of the run, in metres.
  final double worldZ;

  final int lane;
  final CollectibleRole role;

  /// Centre height above the road. Raised tiles have to be jumped for.
  final double height;

  /// Deterministic value used to pick which item a [CollectibleRole.decoy]
  /// shows. Resolved against the sequence length so it is always a real item.
  final int decoySeed;

  double get x => GuzoWorld.laneToX(lane);

  /// True when this tile sits above a standing runner's reach.
  bool get requiresJump => height > GuzoCollectibles.lowHeight;

  /// The text this tile shows for the given player.
  ///
  /// Returns null once the sequence is finished — there is nothing left to
  /// ask for, so remaining tiles simply stop being drawn.
  String? valueFor(SequenceTracker tracker) {
    if (tracker.isComplete) return null;

    switch (role) {
      case CollectibleRole.target:
        return tracker.currentTarget;

      case CollectibleRole.ahead:
        return tracker.itemAt(tracker.currentIndex + 1);

      case CollectibleRole.decoy:
        final int length = tracker.totalCount;
        // A sequence of one has no "other" item to show; fall back to the
        // next one along rather than accidentally showing the target.
        if (length < 3) return tracker.itemAt(tracker.currentIndex + 1);

        // Map onto 1..length-1 so the offset is never zero — a decoy that
        // resolved to the target would be a free pickup dressed as a trap.
        final int offset = 1 + (decoySeed % (length - 1));
        return tracker.itemAt(tracker.currentIndex + offset);
    }
  }
}
