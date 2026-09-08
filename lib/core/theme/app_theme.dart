import 'package:flutter/material.dart';

abstract final class AppTheme {
  // General app surfaces (home / dialogs).
  static const Color background = Color(0xFFF7F7FC);
  static const Color backgroundAccent = Color(0xFFF0EEFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFEEF1F8);
  static const Color surfaceMuted = Color(0xFFE3E8F3);
  static const Color ink = Color(0xFF24263A);
  static const Color inkMuted = Color(0xFF7D829B);
  static const Color primary = Color(0xFF536DFE);
  static const Color accent = Color(0xFFFF6B81);
  static const Color success = Color(0xFF35C98D);
  static const Color warning = Color(0xFFFFB84D);
  static const Color danger = Color(0xFFFF5B6E);

  // Game canvas. Kept separate from app surfaces so gameplay can have a
  // high-contrast arcade identity without turning the whole app dark.
  static const Color gameBackgroundTop = Color(0xFF173A78);
  static const Color gameBackgroundBottom = Color(0xFF0C244F);
  static const Color gameBoard = Color(0xFF112D5C);
  static const Color gameCell = Color(0xFF244575);
  static const Color gameCellEdge = Color(0xFF315686);
  static const Color gameText = Color(0xFFF8FBFF);
  static const Color gameTextMuted = Color(0xFFAFC8EE);
  static const Color gameOverlay = Color(0xCC07162F);

  // Bright, clearly distinguishable puzzle colors. The engine stores only
  // palette indices; presentation owns the actual color system.
  static const List<Color> piecePalette = <Color>[
    Color(0xFF2F9CFF), // blue
    Color(0xFF27D4F2), // cyan
    Color(0xFF42D879), // green
    Color(0xFFFFD447), // yellow
    Color(0xFFFF9F3F), // orange
    Color(0xFFFF5E68), // coral/red
    Color(0xFF9B6BFF), // purple
  ];

  static LinearGradient pieceGradient(int index) {
    final Color base = piecePalette[index % piecePalette.length];
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Color.lerp(base, Colors.white, .30)!,
        base,
        Color.lerp(base, Colors.black, .18)!,
      ],
      stops: const <double>[0, .52, 1],
    );
  }

  static ThemeData get bright => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.light(
          primary: primary,
          secondary: accent,
          surface: surface,
          error: danger,
          onPrimary: Colors.white,
          onSurface: ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          elevation: 0,
          centerTitle: false,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: ink,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.4,
          ),
          headlineMedium: TextStyle(color: ink, fontWeight: FontWeight.w900),
          titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w800),
          bodyLarge: TextStyle(color: ink),
          bodyMedium: TextStyle(color: inkMuted),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: primary,
            textStyle: const TextStyle(fontWeight: FontWeight.w900),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        useMaterial3: true,
      );
}
