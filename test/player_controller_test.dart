import 'package:flutter_test/flutter_test.dart';
import 'package:guzo/game/player/player_controller.dart';
import 'package:guzo/utils/constants.dart';

/// Runs the controller forward by [seconds] in 60 fps steps.
void _advance(PlayerController player, double seconds, {double speed = 10}) {
  const double step = 1 / 60;
  for (double t = 0; t < seconds; t += step) {
    player.update(step, speed * step);
  }
}

void main() {
  group('Lane movement', () {
    test('starts in the middle lane', () {
      final PlayerController player = PlayerController();

      expect(player.lane, 0);
      expect(player.x, 0);
    });

    test('moves one lane at a time and clamps at the edges', () {
      final PlayerController player = PlayerController();

      player.moveLeft();
      expect(player.lane, -1);

      // Already at the left edge — must not walk off the road.
      player.moveLeft();
      expect(player.lane, -1);

      player
        ..moveRight()
        ..moveRight();
      expect(player.lane, 1);

      player.moveRight();
      expect(player.lane, 1);
    });

    test('slides across to the new lane within the configured time', () {
      final PlayerController player = PlayerController()..moveRight();

      // Halfway through the transition it should be partway across.
      _advance(player, GuzoWorld.laneChangeDuration / 2);
      expect(player.x, greaterThan(0));
      expect(player.x, lessThan(GuzoWorld.laneWidth));

      _advance(player, GuzoWorld.laneChangeDuration);
      expect(player.x, closeTo(GuzoWorld.laneWidth, 0.001));
    });

    test('laneOffset reports the remaining travel for the body lean', () {
      final PlayerController player = PlayerController()..moveLeft();

      expect(player.laneOffset, lessThan(0));
      _advance(player, 0.5);
      expect(player.laneOffset, closeTo(0, 0.001));
    });

    test('lane changes are allowed in mid-air', () {
      final PlayerController player = PlayerController()..jump();
      _advance(player, 0.2);
      expect(player.isAirborne, isTrue);

      player.moveRight();
      expect(player.lane, 1);
    });
  });

  group('Jumping', () {
    test('leaves the ground and comes back down on its own', () {
      final PlayerController player = PlayerController()..jump();

      _advance(player, 0.1);
      expect(player.isAirborne, isTrue);
      expect(player.pose, PlayerPose.jumping);

      _advance(player, 1.0);
      expect(player.isAirborne, isFalse);
      expect(player.y, 0);
      expect(player.verticalVelocity, 0);
    });

    test('reaches roughly the documented peak height', () {
      final PlayerController player = PlayerController()..jump();

      double peak = 0;
      for (int i = 0; i < 60; i++) {
        player.update(1 / 60, 0);
        if (player.y > peak) peak = player.y;
      }

      expect(peak, closeTo(GuzoWorld.jumpPeakHeight, 0.1));
    });

    test('a jump pressed in mid-air is buffered and fires on landing', () {
      final PlayerController player = PlayerController()..jump();

      // Press again just before touching down.
      _advance(player, 0.68);
      player.jump();
      _advance(player, 0.15);

      expect(player.isAirborne, isTrue, reason: 'buffered jump should fire');
    });

    test('a buffered jump expires if it was far too early', () {
      final PlayerController player = PlayerController()..jump();

      // Pressed at the very start of a 0.75 s jump — long expired by landing.
      player.jump();
      _advance(player, 1.0);

      expect(player.isAirborne, isFalse);
    });
  });

  group('Sliding', () {
    test('halves the hitbox and then expires', () {
      final PlayerController player = PlayerController()..slide();

      expect(player.isSliding, isTrue);
      expect(player.height, GuzoWorld.slideHeight);
      expect(player.pose, PlayerPose.sliding);

      _advance(player, GuzoWorld.slideDuration + 0.1);
      expect(player.isSliding, isFalse);
      expect(player.height, GuzoWorld.playerHeight);
    });

    test('jumping cancels a slide', () {
      final PlayerController player = PlayerController()..slide();
      expect(player.isSliding, isTrue);

      player.jump();
      _advance(player, 1 / 60);

      expect(player.isSliding, isFalse);
      expect(player.isAirborne, isTrue);
    });

    test('sliding in mid-air dives and slides on landing', () {
      final PlayerController player = PlayerController()..jump();
      _advance(player, 0.3);
      final double heightBeforeDive = player.y;

      player.slide();
      expect(
        player.verticalVelocity,
        lessThanOrEqualTo(GuzoWorld.diveVelocity),
      );

      _advance(player, 0.2);
      expect(player.y, lessThan(heightBeforeDive));
      expect(player.isSliding, isTrue);
    });
  });

  group('Stumbling', () {
    test('costs speed without ending the run', () {
      final PlayerController player = PlayerController();
      expect(player.speedMultiplier, 1.0);

      expect(player.stumble(), isTrue);
      expect(player.speedMultiplier, GuzoWorld.stumbleSpeedFactor);
      expect(player.pose, PlayerPose.stumbling);

      _advance(player, GuzoWorld.stumbleDuration + 0.05);
      expect(player.speedMultiplier, 1.0);
    });

    test('is refused while still invulnerable from the last hit', () {
      final PlayerController player = PlayerController();

      expect(player.stumble(), isTrue);
      expect(player.stumble(), isFalse);

      _advance(player, GuzoWorld.invulnerableDuration + 0.05);
      expect(player.stumble(), isTrue);
    });

    test('cancels an active slide', () {
      final PlayerController player = PlayerController()..slide();

      player.stumble();
      expect(player.isSliding, isFalse);
    });
  });

  group('Animation and reset', () {
    test('the run cycle advances with distance and wraps', () {
      final PlayerController player = PlayerController();

      player.update(1 / 60, 1.0);
      expect(player.runCycle, closeTo(GuzoVisuals.runCyclesPerMetre, 0.0001));

      _advance(player, 5);
      expect(player.runCycle, inInclusiveRange(0, 1));
    });

    test('a standing player does not drift vertically', () {
      final PlayerController player = PlayerController();

      _advance(player, 5);

      expect(player.y, 0);
      expect(player.verticalVelocity, 0);
    });

    test('reset returns every field to its starting value', () {
      final PlayerController player = PlayerController()
        ..moveRight()
        ..jump()
        ..stumble();
      _advance(player, 0.3);

      player.reset();

      expect(player.lane, 0);
      expect(player.x, 0);
      expect(player.y, 0);
      expect(player.verticalVelocity, 0);
      expect(player.runCycle, 0);
      expect(player.isSliding, isFalse);
      expect(player.isStumbling, isFalse);
      expect(player.isInvulnerable, isFalse);
      expect(player.pose, PlayerPose.running);
    });
  });
}
