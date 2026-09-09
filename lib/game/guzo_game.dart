import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../education/sequence_definition.dart';
import '../education/sequence_library.dart';
import '../education/sequence_tracker.dart';
import '../utils/constants.dart';
import 'camera/perspective_camera.dart';
import 'components/sky_background.dart';
import 'components/track_view.dart';
import 'input/swipe_recognizer.dart';
import 'player/player_controller.dart';
import 'systems/collection_system.dart';
import 'systems/collision_system.dart';
import 'world/track_chunk.dart';
import 'world/track_manager.dart';

/// Short-lived feedback from the last pickup, for the HUD to flash.
enum PickupFeedback { none, correct, wrong, finished }

/// The root Flame game for GUZO.
///
/// It owns the simulation and wires input to it; all drawing lives in
/// [TrackView] and [SkyBackground]. The split matters beyond tidiness: the
/// simulation here is pure metres and seconds with no reference to pixels, so
/// the Phase 6 host can run exactly this logic to validate what a client
/// reports without knowing anything about that client's screen.
///
/// Touch input arrives from the Flutter layer via [onSwipeStart] and friends
/// rather than through Flame's gesture detectors, which lets one
/// [GestureDetector] serve both the swipe controls and a plain tap without the
/// two recognizers fighting.
class GuzoGame extends FlameGame with KeyboardEvents {
  /// [seed] fixes the entire track and [sequence] fixes what must be
  /// collected. In single player both are local choices; in multiplayer the
  /// host picks them and every client is given the same values, which is what
  /// makes all players race an identical world toward an identical goal.
  GuzoGame({int? seed, SequenceDefinition? sequence})
    : seed = seed ?? DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
      sequence = sequence ?? SequenceLibrary.defaultSequence;

  final int seed;
  final SequenceDefinition sequence;

  /// Projects the metre-based world onto the screen, and carries the camera's
  /// travelled distance — the authoritative "where are we" value.
  final PerspectiveCamera perspective = PerspectiveCamera();

  final PlayerController player = PlayerController();
  final CollisionSystem collisions = CollisionSystem();
  final CollectionSystem collection = CollectionSystem();

  late final SequenceTracker tracker = SequenceTracker(sequence);
  late final TrackManager track = TrackManager(seed: seed);

  final SwipeRecognizer _swipe = SwipeRecognizer();

  /// Metres run, for the HUD.
  final ValueNotifier<int> distanceMetres = ValueNotifier<int>(0);

  /// Current speed in m/s, for the HUD.
  final ValueNotifier<double> speedNotifier = ValueNotifier<double>(
    GuzoWorld.startSpeed,
  );

  /// Number of obstacles hit this run.
  final ValueNotifier<int> stumbles = ValueNotifier<int>(0);

  /// How many sequence items have been collected. The HUD watches this and
  /// reads [tracker] for the detail, so progress redraws only when it changes.
  final ValueNotifier<int> collectedCount = ValueNotifier<int>(0);

  /// The most recent pickup result, for a brief HUD flash.
  final ValueNotifier<PickupFeedback> feedback = ValueNotifier<PickupFeedback>(
    PickupFeedback.none,
  );

  /// Flips once the sequence is finished. The game screen watches this and
  /// shows the completion overlay.
  final ValueNotifier<bool> isComplete = ValueNotifier<bool>(false);

  /// Seconds since the run started; drives cosmetic wobble and flicker only.
  double elapsed = 0;

  /// Seconds of actual running, frozen once the sequence is complete.
  double runTime = 0;

  double _feedbackUntil = 0;

  /// How long a pickup flash stays up, in seconds.
  static const double _feedbackDuration = 0.55;

  /// Forward speed right now, after any stumble penalty.
  double get speed =>
      GuzoWorld.speedAt(perspective.travelled) * player.speedMultiplier;

  /// Distance run so far, in metres.
  double get distance => perspective.travelled;

  @override
  Color backgroundColor() => GuzoColors.skyBottom;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    perspective.resize(size);
  }

  @override
  Future<void> onLoad() async {
    perspective.resize(size);
    track.prime();
    await addAll(<Component>[SkyBackground(), TrackView()]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    elapsed += dt;
    _expireFeedback();

    // The world stops advancing the moment the sequence is finished, so the
    // completion overlay sits over a still scene rather than a moving one.
    if (isComplete.value) return;

    runTime += dt;
    final double distanceMoved = speed * dt;

    perspective.update(dt, distanceMoved, player.x);
    player.update(dt, distanceMoved);
    track.ensureGenerated(perspective.travelled);

    _resolveCollisions();
    _resolveCollections();
    _publishHudValues();
  }

  void _resolveCollisions() {
    final double playerWorldZ = perspective.playerWorldZ;
    final Obstacle? hit = collisions.check(
      player,
      track.obstaclesNear(playerWorldZ, CollisionSystem.searchWindow),
      playerWorldZ,
    );
    if (hit == null) return;

    // stumble() refuses while the runner is still protected from a previous
    // hit, so a cluster of obstacles costs one stumble, not three.
    if (player.stumble()) {
      stumbles.value++;
    }
  }

  void _resolveCollections() {
    final double playerWorldZ = perspective.playerWorldZ;
    final List<CollectionEvent> events = collection.collect(
      player,
      track.collectiblesNear(playerWorldZ, CollectionSystem.searchWindow),
      tracker,
      playerWorldZ,
    );
    if (events.isEmpty) return;

    for (final CollectionEvent event in events) {
      _showFeedback(
        event.finishedSequence
            ? PickupFeedback.finished
            : event.isCorrect
            ? PickupFeedback.correct
            : PickupFeedback.wrong,
      );

      if (event.finishedSequence) {
        isComplete.value = true;
      }
    }

    collectedCount.value = tracker.collectedCount;
  }

  void _showFeedback(PickupFeedback value) {
    feedback.value = value;
    _feedbackUntil = elapsed + _feedbackDuration;
  }

  void _expireFeedback() {
    if (feedback.value == PickupFeedback.none) return;
    // The finished flash is permanent: the run is over and the overlay is up.
    if (feedback.value == PickupFeedback.finished) return;
    if (elapsed >= _feedbackUntil) feedback.value = PickupFeedback.none;
  }

  void _publishHudValues() {
    final int metres = perspective.travelled.floor();
    if (metres != distanceMetres.value) distanceMetres.value = metres;

    // Only notify on a visible change, so the HUD is not rebuilt every frame.
    final double current = speed;
    if ((current - speedNotifier.value).abs() > 0.05) {
      speedNotifier.value = current;
    }
  }

  // --- Input --------------------------------------------------------------

  /// Routes one recognised gesture to the runner.
  void applySwipe(SwipeDirection direction) {
    if (isComplete.value) return;

    switch (direction) {
      case SwipeDirection.left:
        player.moveLeft();
      case SwipeDirection.right:
        player.moveRight();
      case SwipeDirection.up:
        player.jump();
      case SwipeDirection.down:
        player.slide();
    }
  }

  void onSwipeStart() => _swipe.start();

  /// Feeds a drag delta in logical pixels; fires at most one swipe per drag.
  void onSwipeMove(Offset delta) {
    final SwipeDirection? direction = _swipe.update(delta);
    if (direction != null) applySwipe(direction);
  }

  void onSwipeStop() => _swipe.end();

  /// A plain tap jumps: the simplest possible control for a young child.
  void onTapJump() => applySwipe(SwipeDirection.up);

  /// Keyboard support exists so the game can be driven on a desktop build
  /// during development; it is not part of the shipped mobile controls.
  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        applySwipe(SwipeDirection.left);
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        applySwipe(SwipeDirection.right);
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
      case LogicalKeyboardKey.space:
        applySwipe(SwipeDirection.up);
      case LogicalKeyboardKey.arrowDown:
      case LogicalKeyboardKey.keyS:
        applySwipe(SwipeDirection.down);
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // --- Lifecycle ----------------------------------------------------------

  /// Returns the run to its starting state, keeping the same seed and
  /// sequence, and so the same track and the same goal.
  void restart() {
    perspective.reset();
    player.reset();
    collisions.reset();
    collection.reset();
    tracker.reset();
    track.reset();

    elapsed = 0;
    runTime = 0;
    _feedbackUntil = 0;
    distanceMetres.value = 0;
    speedNotifier.value = GuzoWorld.startSpeed;
    stumbles.value = 0;
    collectedCount.value = 0;
    feedback.value = PickupFeedback.none;
    isComplete.value = false;
  }

  @override
  void onRemove() {
    distanceMetres.dispose();
    speedNotifier.dispose();
    stumbles.dispose();
    collectedCount.dispose();
    feedback.dispose();
    isComplete.dispose();
    super.onRemove();
  }
}
