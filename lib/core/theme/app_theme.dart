import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color background = Color(0xFFF7F7FC);
  static const Color backgroundAccent = Color(0xFFF0EEFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFEEF1F8);
  static const Color surfaceMuted = Color(0xFFE3E8F3);
  static const Color ink = Color(0xFF24263A);
  static const Color inkMuted = Color(0xFF7D829B);
  static const Color primary = Color(0xFF6C63FF);
  static const Color accent = Color(0xFFFF6B81);
  static const Color success = Color(0xFF35C98D);
  static const Color warning = Color(0xFFFFB84D);
  static const Color danger = Color(0xFFFF5B6E);

  static const List<Color> piecePalette = <Color>[
    Color(0xFF6C63FF),
    Color(0xFF4CA7FF),
    Color(0xFFFF7657),
    Color(0xFFFFC84B),
    Color(0xFF39CFA0),
    Color(0xFFE96BFF),
  ];

  static LinearGradient pieceGradient(int index) {
    final Color base = piecePalette[index % piecePalette.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Color.lerp(base, Colors.white, .20)!,
        base,
        Color.lerp(base, Colors.black, .10)!,
      ],
      stops: const <double>[0, .55, 1],
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
