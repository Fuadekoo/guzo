import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/guzo_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // GUZO is played in portrait, held one-handed: it is the orientation of the
  // behind-the-runner genre and of the app's card-based menus.
  await Flame.device.setPortrait();
  await Flame.device.fullScreen();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  runApp(const GuzoApp());
}
