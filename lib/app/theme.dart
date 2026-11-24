import 'package:material_ui/material_ui.dart';

/// Rose/violet theme for Mboa Kids, tuned for a 4-year-old audience:
/// large touch targets, soft bright colors, no small text.
class MboaKidsTheme {
  MboaKidsTheme._();

  static const Color pink = Color(0xFFFF6FA5);
  static const Color purple = Color(0xFF8B5FBF);
  static const Color lightPink = Color(0xFFFFD6E8);
  static const Color lightPurple = Color(0xFFE4D4F4);

  /// Warm accents added for the Refonte visuelle (CLAUDE.md section 10):
  /// used in the new scenes (ciel/sol, baobab) alongside the rose/violet
  /// above, never replacing it in buttons or the app bar.
  static const Color terracotta = Color(0xFFE2793D);
  static const Color gold = Color(0xFFF2B33D);
  static const Color skyWarm = Color(0xFFFFE8C7);
  static const Color groundWarm = Color(0xFFC98A52);

  /// Minimum touch target size required by CLAUDE.md (>= 64 dp).
  static const double minTapTarget = 64;

  static ThemeData get theme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: purple,
      primary: purple,
      secondary: pink,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightPurple,
      appBarTheme: const AppBarTheme(
        backgroundColor: purple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pink,
          foregroundColor: Colors.white,
          minimumSize: const Size(minTapTarget, minTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontWeight: FontWeight.bold,
          color: purple,
        ),
      ),
    );
  }
}
