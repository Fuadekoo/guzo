import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Builds the single [ThemeData] used by the whole app.
///
/// Uses the bundled system font on purpose — GUZO must work with no internet,
/// so no runtime font downloading. A bundled custom font can be dropped into
/// `assets/` and wired through [_textTheme] later without touching widgets.
abstract final class GuzoTheme {
  static ThemeData build() {
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: GuzoColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: GuzoColors.primary,
          onPrimary: GuzoColors.onPrimary,
          secondary: GuzoColors.secondary,
          onSecondary: GuzoColors.onPrimary,
          surface: GuzoColors.surface,
          onSurface: GuzoColors.ink,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: GuzoColors.surfaceMuted,
      textTheme: _textTheme,
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: GuzoColors.ink,
        contentTextStyle: TextStyle(
          color: GuzoColors.onPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 64,
      fontWeight: FontWeight.w900,
      letterSpacing: 6,
      color: GuzoColors.onPrimary,
      height: 1.0,
    ),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: GuzoColors.ink,
    ),
    titleMedium: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: GuzoColors.ink,
    ),
    bodyMedium: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: GuzoColors.inkSoft,
    ),
    labelLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.4,
      color: GuzoColors.onPrimary,
    ),
  );
}
