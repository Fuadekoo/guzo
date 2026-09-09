import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../utils/constants.dart';
import 'guzo_theme.dart';

/// Root widget of the GUZO application.
class GuzoApp extends StatelessWidget {
  const GuzoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: GuzoStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: GuzoTheme.build(),
      home: const HomeScreen(),
    );
  }
}
