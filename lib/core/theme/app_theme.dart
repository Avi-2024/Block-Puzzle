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
  static const Color primary = Color(0xFF766BFF);
  static const Color accent = Color(0xFFFF64B7);
  static const Color success = Color(0xFF38F2A0);
  static const Color warning = Color(0xFFFFDA64);
  static const Color danger = Color(0xFFFF5573);

  // Game canvas V2 tokens. These values are tuned for a casual puzzle game:
  // saturated enough to feel premium, but dark enough to keep the 8×8 board
  // and score readable on low/mid brightness Android devices.
  static const Color gameBackgroundTop = Color(0xFF3149C5);
  static const Color gameBackgroundMid = Color(0xFF142F82);
  static const Color gameBackgroundBottom = Color(0xFF05142F);
  static const Color gameBoard = Color(0xFF092D6E);
  static const Color gameBoardDeep = Color(0xFF020F31);
  static const Color gameCell = Color(0xFF0D377D);
  static const Color gameCellEdge = Color(0xFF65B7FF);
  static const Color gameText = Color(0xFFF9FCFF);
  static const Color gameTextMuted = Color(0xFFD2E4FF);
  static const Color gameOverlay = Color(0xD9071430);

  // Bright, clearly distinguishable puzzle colors. The engine stores only
  // palette indices; presentation owns the actual color system.
  static const List<Color> piecePalette = <Color>[
    Color(0xFF39A9FF), // electric blue
    Color(0xFF20E9FF), // cyan
    Color(0xFF42F889), // neon green
    Color(0xFFFFDD58), // gold
    Color(0xFFFFA142), // orange
    Color(0xFFFF4F73), // coral/red
    Color(0xFFAA70FF), // purple
  ];

  static LinearGradient pieceGradient(int index) {
    final Color base = piecePalette[index % piecePalette.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Color.lerp(base, Colors.white, .74)!,
        Color.lerp(base, Colors.white, .30)!,
        base,
        Color.lerp(base, Colors.black, .28)!,
        Color.lerp(base, Colors.black, .48)!,
      ],
      stops: const <double>[0, .16, .52, .78, 1],
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
        stops: <double>[0, .44, 1],
      );

  static LinearGradient get boardGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFF124292),
          gameBoard,
          Color(0xFF061D50),
          gameBoardDeep,
        ],
        stops: <double>[0, .38, .72, 1],
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
