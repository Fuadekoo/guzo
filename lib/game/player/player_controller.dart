import 'dart:math' as math;

import '../../utils/constants.dart';

/// What the runner is doing right now, for the painter to draw.
enum PlayerPose { running, jumping, sliding, stumbling }

/// The runner's simulation state.
///
/// Deliberately free of Flame, Flutter and pixels: it is a plain object with
/// [update] and a handful of intent methods. That keeps it fast to unit test,
/// and in Phase 6 it becomes the piece the host re-runs to validate what a
/// client claims to have done.
class PlayerController {
  /// Lane index the runner is heading for: -1, 0 or 1.
  int lane = 0;

  /// Sideways position in metres. Eases toward the target lane.
  double x = 0;

  /// Height above the road in metres.
  double y = 0;

  double verticalVelocity = 0;

  /// Run animation phase in `[0, 1)`. One cycle is two footfalls.
  double runCycle = 0;

  double _slideTimer = 0;
  double _stumbleTimer = 0;
  double _invulnerableTimer = 0;
  double _jumpBuffer = 0;
  double _slideBuffer = 0;

  // --- Derived state ------------------------------------------------------

  bool get isAirborne => y > 0;
  bool get isSliding => _slideTimer > 0;
  bool get isStumbling => _stumbleTimer > 0;

  /// True while a recent hit protects the runner from being hit again.
  bool get isInvulnerable => _invulnerableTimer > 0;

  /// Seconds left of the current stumble; drives the HUD flash.
  double get stumbleRemaining => _stumbleTimer;

  /// Height of the runner's hitbox — halved while sliding, which is the only
  /// thing that lets a hurdle be cleared.
  double get height =>
      isSliding ? GuzoWorld.slideHeight : GuzoWorld.playerHeight;

  /// Fraction of the normal forward speed. A stumble costs speed; it never
  /// ends the run.
  double get speedMultiplier =>
      isStumbling ? GuzoWorld.stumbleSpeedFactor : 1.0;

  /// Sideways position the runner is easing toward.
  double get targetX => GuzoWorld.laneToX(lane);

  /// How far the runner still has to travel sideways, in metres. The painter
  /// leans the body into the turn with this.
  double get laneOffset => targetX - x;

  PlayerPose get pose {
    if (isStumbling) return PlayerPose.stumbling;
    if (isAirborne) return PlayerPose.jumping;
    if (isSliding) return PlayerPose.sliding;
    return PlayerPose.running;
  }

  // --- Intents ------------------------------------------------------------

  /// Lane changes are always allowed, including mid-air, which is what makes
  /// the controls feel forgiving.
  void moveLeft() {
    if (lane > -1) lane--;
  }

  void moveRight() {
    if (lane < 1) lane++;
  }

  void jump() {
    if (isAirborne) {
      // Pressed too early — remember it and fire on landing.
      _jumpBuffer = GuzoWorld.inputBufferDuration;
      return;
    }
    _startJump();
  }

  void slide() {
    if (isAirborne) {
      // Dive: cut the jump short and slide the moment the runner lands.
      verticalVelocity = math.min(verticalVelocity, GuzoWorld.diveVelocity);
      _slideBuffer = GuzoWorld.inputBufferDuration;
      return;
    }
    _startSlide();
  }

  /// Applies a collision. Returns false when the runner was still protected by
  /// invulnerability, so the caller can skip the sound and shake.
  bool stumble() {
    if (isInvulnerable) return false;
    _stumbleTimer = GuzoWorld.stumbleDuration;
    _invulnerableTimer = GuzoWorld.invulnerableDuration;
    _slideTimer = 0;
    return true;
  }

  // --- Simulation ---------------------------------------------------------

  /// Advances one frame. [distanceMoved] is the forward distance covered this
  /// frame, used only to keep the leg animation in step with actual speed.
  void update(double dt, double distanceMoved) {
    _tickTimers(dt);
    _updateLane(dt);
    _updateVertical(dt);

    runCycle = (runCycle + distanceMoved * GuzoVisuals.runCyclesPerMetre) % 1.0;
  }

  void _tickTimers(double dt) {
    _slideTimer = math.max(0, _slideTimer - dt);
    _stumbleTimer = math.max(0, _stumbleTimer - dt);
    _invulnerableTimer = math.max(0, _invulnerableTimer - dt);
    _jumpBuffer = math.max(0, _jumpBuffer - dt);
    _slideBuffer = math.max(0, _slideBuffer - dt);
  }

  void _updateLane(double dt) {
    final double delta = targetX - x;
    if (delta == 0) return;

    final double step =
        (GuzoWorld.laneWidth / GuzoWorld.laneChangeDuration) * dt;
    x = delta.abs() <= step ? targetX : x + step * delta.sign;
  }

  void _updateVertical(double dt) {
    // Skip entirely while standing still on the road: no gravity integration,
    // no floating-point drift.
    if (!isAirborne && verticalVelocity == 0) return;

    verticalVelocity += GuzoWorld.gravity * dt;
    y += verticalVelocity * dt;

    if (y <= 0) {
      y = 0;
      verticalVelocity = 0;
      _onLanded();
    }
  }

  void _onLanded() {
    // A queued slide wins over a queued jump: it is the input the player gave
    // to get down fast in the first place.
    if (_slideBuffer > 0) {
      _startSlide();
    } else if (_jumpBuffer > 0) {
      _startJump();
    }
  }

  void _startJump() {
    _slideTimer = 0;
    verticalVelocity = GuzoWorld.jumpVelocity;
    _jumpBuffer = 0;
  }

  void _startSlide() {
    _slideTimer = GuzoWorld.slideDuration;
    _slideBuffer = 0;
  }

  void reset() {
    lane = 0;
    x = 0;
    y = 0;
    verticalVelocity = 0;
    runCycle = 0;
    _slideTimer = 0;
    _stumbleTimer = 0;
    _invulnerableTimer = 0;
    _jumpBuffer = 0;
    _slideBuffer = 0;
  }
}
