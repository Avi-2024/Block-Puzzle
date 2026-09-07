import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const Color background = Color(0xFF080C18);
  static const Color surface = Color(0xFF121A2D);
  static const Color surfaceSoft = Color(0xFF1A2540);
  static const Color surfaceMuted = Color(0xFF222E4D);
  static const Color primary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFF22D3EE);
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFFB7185);

  static const List<Color> piecePalette = <Color>[
    Color(0xFF8B5CF6),
    Color(0xFF22D3EE),
    Color(0xFF34D399),
    Color(0xFFF59E0B),
    Color(0xFFFB7185),
    Color(0xFF60A5FA),
  ];

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: accent,
          surface: surface,
          error: danger,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: -1.4,
          ),
          headlineMedium: TextStyle(fontWeight: FontWeight.w800),
          titleLarge: TextStyle(fontWeight: FontWeight.w800),
          bodyLarge: TextStyle(color: Color(0xFFD8DEEE)),
        ),
        useMaterial3: true,
      );
}
