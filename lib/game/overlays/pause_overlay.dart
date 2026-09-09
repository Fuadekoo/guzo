import 'package:flutter/material.dart';

import '../../services/audio_service.dart';
import '../../services/storage_service.dart';
import '../../utils/constants.dart';
import '../../widgets/guzo_button.dart';

/// Full-screen pause menu shown over a frozen Flame canvas.
///
/// Carries the sound and music switches. They belong on a settings screen and
/// will move there in Phase 7, but shipping audio with no way to silence it is
/// not something to leave for later — a parent needs to mute the game the
/// moment they want to, not after a menu redesign.
class PauseOverlay extends StatefulWidget {
  const PauseOverlay({required this.onResume, required this.onHome, super.key});

  final VoidCallback onResume;
  final VoidCallback onHome;

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay> {
  final StorageService _storage = StorageService.instance;
  final AudioService _audio = AudioService.instance;

  Future<void> _setSound(bool value) async {
    setState(() {});
    await _storage.setSoundEnabled(value);
    await _audio.setSoundEnabled(value);
    if (mounted) setState(() {});
  }

  Future<void> _setMusic(bool value) async {
    setState(() {});
    await _storage.setMusicEnabled(value);
    await _audio.setMusicEnabled(value);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: GuzoColors.scrim,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(GuzoSizes.spaceMd),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: GuzoSizes.buttonMaxWidth,
              ),
              child: Container(
                padding: const EdgeInsets.all(GuzoSizes.spaceLg),
                decoration: BoxDecoration(
                  color: GuzoColors.surface,
                  borderRadius: BorderRadius.circular(GuzoSizes.radiusLg),
                  boxShadow: GuzoShadows.card,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      GuzoStrings.paused,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 26,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: GuzoSizes.spaceLg),
                    _AudioToggle(
                      label: GuzoStrings.sound,
                      icon: Icons.volume_up_rounded,
                      value: _storage.soundEnabled,
                      onChanged: _setSound,
                    ),
                    _AudioToggle(
                      label: GuzoStrings.music,
                      icon: Icons.music_note_rounded,
                      value: _storage.musicEnabled,
                      onChanged: _setMusic,
                    ),
                    const SizedBox(height: GuzoSizes.spaceLg),
                    GuzoButton(
                      label: GuzoStrings.resume,
                      icon: Icons.play_arrow_rounded,
                      onPressed: widget.onResume,
                    ),
                    const SizedBox(height: GuzoSizes.spaceMd),
                    GuzoButton(
                      label: GuzoStrings.home,
                      icon: Icons.home_rounded,
                      color: GuzoColors.secondary,
                      shadowColor: GuzoColors.secondaryDark,
                      onPressed: widget.onHome,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AudioToggle extends StatelessWidget {
  const _AudioToggle({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GuzoSizes.spaceXs),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            color: value ? GuzoColors.secondary : GuzoColors.inkSoft,
            size: 24,
          ),
          const SizedBox(width: GuzoSizes.spaceMd),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Switch(
            value: value,
            activeThumbColor: GuzoColors.surface,
            activeTrackColor: GuzoColors.secondary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
