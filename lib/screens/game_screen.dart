import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../education/sequence_definition.dart';
import '../game/guzo_game.dart';
import '../game/input/swipe_recognizer.dart';
import '../game/overlays/complete_overlay.dart';
import '../game/overlays/game_hud.dart';
import '../game/overlays/pause_overlay.dart';
import '../utils/constants.dart';

/// Hosts the Flame canvas, its Flutter overlays and the touch controls.
///
/// The gesture detector sits *outside* [GameWidget], so the HUD buttons drawn
/// inside it still win their own taps: Flutter hit-tests children first, and
/// the gesture arena hands a genuine drag to the pan recogniser and a genuine
/// tap on a button to the button.
class GameScreen extends StatefulWidget {
  const GameScreen({this.seed, this.sequence, super.key});

  /// Fixes the track. Left null in single player; Phase 5 passes the host's
  /// seed here so every device races the same world.
  final int? seed;

  /// What the player must collect. Defaults to the library's default.
  final SequenceDefinition? sequence;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GuzoGame _game = GuzoGame(
    seed: widget.seed,
    sequence: widget.sequence,
  );
  final SwipeRecognizer _swipe = SwipeRecognizer();
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _game.isComplete.addListener(_onCompletionChanged);
  }

  @override
  void dispose() {
    // The notifier belongs to the game and is disposed with it, but this
    // listener has to come off first.
    _game.isComplete.removeListener(_onCompletionChanged);
    super.dispose();
  }

  /// The game flips this when the last item of the sequence is collected.
  void _onCompletionChanged() {
    if (_game.isComplete.value) {
      _game.overlays.add(GuzoOverlays.complete);
    } else {
      _game.overlays.remove(GuzoOverlays.complete);
    }
  }

  void _pause() {
    if (_isPaused || _game.isComplete.value) return;
    _game.pauseEngine();
    _game.overlays.add(GuzoOverlays.pause);
    setState(() => _isPaused = true);
  }

  void _resume() {
    if (!_isPaused) return;
    _game.overlays.remove(GuzoOverlays.pause);
    _game.resumeEngine();
    setState(() => _isPaused = false);
  }

  void _playAgain() {
    // restart() clears isComplete, which pulls the overlay via the listener.
    _game.restart();
    _resume();
  }

  void _goHome() => Navigator.of(context).pop();

  /// System back pauses first, and only leaves the run on a second press.
  void _handlePop(bool didPop, Object? result) {
    if (didPop) return;
    if (_isPaused || _game.isComplete.value) {
      _goHome();
    } else {
      _pause();
    }
  }

  // --- Touch controls -----------------------------------------------------

  bool get _controlsLocked => _isPaused || _game.isComplete.value;

  void _onPanStart(DragStartDetails details) {
    if (_controlsLocked) return;
    _swipe.start();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_controlsLocked) return;
    final SwipeDirection? direction = _swipe.update(details.delta);
    if (direction != null) _game.applySwipe(direction);
  }

  void _onPanEnd(DragEndDetails details) => _swipe.end();

  void _onTap() {
    if (_controlsLocked) return;
    _game.onTapJump();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: _handlePop,
      child: Scaffold(
        backgroundColor: GuzoColors.skyBottom,
        body: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onTap: _onTap,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onPanCancel: _swipe.end,
          child: GameWidget<GuzoGame>(
            game: _game,
            // Keyboard control on desktop builds needs the canvas focused.
            autofocus: true,
            initialActiveOverlays: const <String>[GuzoOverlays.hud],
            overlayBuilderMap:
                <String, Widget Function(BuildContext, GuzoGame)>{
                  GuzoOverlays.hud: (BuildContext context, GuzoGame game) =>
                      GameHud(game: game, onPause: _pause),
                  GuzoOverlays.pause: (BuildContext context, GuzoGame game) =>
                      PauseOverlay(onResume: _resume, onHome: _goHome),
                  GuzoOverlays.complete:
                      (BuildContext context, GuzoGame game) => CompleteOverlay(
                        game: game,
                        onPlayAgain: _playAgain,
                        onHome: _goHome,
                      ),
                },
          ),
        ),
      ),
    );
  }
}
