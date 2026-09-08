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
  static const Color primary = Color(0xFF6C63FF);
  static const Color accent = Color(0xFFFF5FA2);
  static const Color success = Color(0xFF37E79A);
  static const Color warning = Color(0xFFFFD257);
  static const Color danger = Color(0xFFFF5470);

  // Game canvas V2 tokens. These values are tuned for a casual puzzle game:
  // saturated enough to feel premium, but dark enough to keep the 8×8 board
  // and score readable on low/mid brightness Android devices.
  static const Color gameBackgroundTop = Color(0xFF253AA1);
  static const Color gameBackgroundMid = Color(0xFF122D72);
  static const Color gameBackgroundBottom = Color(0xFF071A3D);
  static const Color gameBoard = Color(0xFF0B2A68);
  static const Color gameBoardDeep = Color(0xFF061A47);
  static const Color gameCell = Color(0xFF173F7F);
  static const Color gameCellEdge = Color(0xFF2B64B4);
  static const Color gameText = Color(0xFFF9FCFF);
  static const Color gameTextMuted = Color(0xFFBBD1F7);
  static const Color gameOverlay = Color(0xD9071430);

  // Bright, clearly distinguishable puzzle colors. The engine stores only
  // palette indices; presentation owns the actual color system.
  static const List<Color> piecePalette = <Color>[
    Color(0xFF35A5FF), // electric blue
    Color(0xFF22E3FF), // cyan
    Color(0xFF43F17E), // neon green
    Color(0xFFFFD84F), // gold
    Color(0xFFFFA33D), // orange
    Color(0xFFFF4F6B), // coral/red
    Color(0xFFA66BFF), // purple
  ];

  static LinearGradient pieceGradient(int index) {
    final Color base = piecePalette[index % piecePalette.length];
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Color.lerp(base, Colors.white, .42)!,
        Color.lerp(base, Colors.white, .08)!,
        base,
        Color.lerp(base, Colors.black, .26)!,
      ],
      stops: const <double>[0, .18, .62, 1],
    );
  }

  static LinearGradient get gameBackgroundGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          gameBackgroundTop,
          gameBackgroundMid,
          gameBackgroundBottom,
        ],
        stops: <double>[0, .46, 1],
      );

  static LinearGradient get boardGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[gameBoard, gameBoardDeep],
      );

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
