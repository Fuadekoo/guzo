import 'sequence_definition.dart';

/// What happened when an item was offered to the tracker.
enum CollectionOutcome {
  /// The item matched the current target and progress advanced.
  correct,

  /// The item was not the current target. Nothing changed.
  wrong,

  /// That was the final item — the sequence is finished.
  completed,

  /// The sequence was already finished before this offer.
  alreadyComplete,
}

/// Tracks one player's progress through a [SequenceDefinition].
///
/// The rule from the brief lives here and nowhere else: **the sequence cannot
/// be skipped**. If the target is C and the player collects D, D does not
/// count and the target stays C.
///
/// Pure and dependency-free on purpose. In Phase 6 the host keeps one of these
/// per player and re-runs [offer] to validate a client's claimed pickup, so it
/// must never touch rendering, timing or randomness.
class SequenceTracker {
  SequenceTracker(this.definition);

  final SequenceDefinition definition;

  int _index = 0;

  /// How many items have been collected so far.
  int get collectedCount => _index;

  int get totalCount => definition.length;

  bool get isComplete => _index >= definition.length;

  /// Fraction complete, in `[0, 1]`.
  double get progress => totalCount == 0 ? 1 : _index / totalCount;

  /// The item the player must collect next, or null once finished.
  String? get currentTarget => isComplete ? null : definition.items[_index];

  /// Index of the current target, clamped to the last item when complete.
  int get currentIndex => isComplete ? definition.length - 1 : _index;

  /// The item at [index], wrapping around the sequence.
  ///
  /// Used to pick decoys, which is why it wraps rather than returning null:
  /// a decoy is always some other real item from the same alphabet, never a
  /// blank tile.
  String itemAt(int index) => definition.items[index % definition.length];

  /// True when [value] is what the player currently needs.
  bool isTarget(String value) => !isComplete && value == currentTarget;

  /// Offers a collected value to the sequence.
  ///
  /// Advances only on an exact match with [currentTarget].
  CollectionOutcome offer(String value) {
    if (isComplete) return CollectionOutcome.alreadyComplete;
    if (value != currentTarget) return CollectionOutcome.wrong;

    _index++;
    return isComplete ? CollectionOutcome.completed : CollectionOutcome.correct;
  }

  /// A window of items centred on the current target, for the HUD ribbon.
  ///
  /// Returns up to [size] entries and slides the window so the target stays
  /// visible at both ends of the sequence rather than running off the edge.
  List<SequenceSlot> window(int size) {
    if (definition.length <= size) {
      return <SequenceSlot>[
        for (int i = 0; i < definition.length; i++) _slotAt(i),
      ];
    }

    int start = currentIndex - (size ~/ 2);
    start = start.clamp(0, definition.length - size);

    return <SequenceSlot>[
      for (int i = start; i < start + size; i++) _slotAt(i),
    ];
  }

  SequenceSlot _slotAt(int index) => SequenceSlot(
    value: definition.items[index],
    index: index,
    collected: index < _index,
    isCurrent: !isComplete && index == _index,
  );

  void reset() => _index = 0;
}

/// One entry in the HUD's progress ribbon.
class SequenceSlot {
  const SequenceSlot({
    required this.value,
    required this.index,
    required this.collected,
    required this.isCurrent,
  });

  final String value;
  final int index;
  final bool collected;
  final bool isCurrent;
}
