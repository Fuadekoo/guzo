import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/guzo_app.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // GUZO is played in portrait, held one-handed: it is the orientation of the
  // behind-the-runner genre and of the app's card-based menus.
  await Flame.device.setPortrait();
  await Flame.device.fullScreen();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  // Settings first, so audio starts in the state the player last chose.
  // Both services swallow their own failures and fall back to sane defaults,
  // so a device with no working store or audio back end still gets a game.
  await StorageService.instance.init();
  await AudioService.instance.init(
    sound: StorageService.instance.soundEnabled,
    music: StorageService.instance.musicEnabled,
  );
  // The theme loops for the whole session rather than starting and stopping
  // with each run, so moving between the menu and a race has no silent seam.
  await AudioService.instance.startMusic();

  runApp(const GuzoApp());
}
