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

  // Approved gameplay direction: Blockiva should feel board-first, glossy,
  // colorful and relaxed. These tokens deliberately keep the screen close to
  // the approved reference while staying original and readable on Android.
  static const Color gameBackgroundTop = Color(0xFF142CC8);
  static const Color gameBackgroundMid = Color(0xFF35218A);
  static const Color gameBackgroundBottom = Color(0xFF061032);
  static const Color gameBoard = Color(0xFF071A54);
  static const Color gameBoardDeep = Color(0xFF020819);
  static const Color gameCell = Color(0xFF102761);
  static const Color gameCellEdge = Color(0xFF3D82FF);
  static const Color gameText = Color(0xFFFFFFFF);
  static const Color gameTextMuted = Color(0xFFD9E7FF);
  static const Color gameOverlay = Color(0xDC071330);

  // Bright, clearly distinguishable puzzle colors. The engine stores only
  // palette indices; presentation owns the actual color system.
  static const List<Color> piecePalette = <Color>[
    Color(0xFF17A8FF), // blue
    Color(0xFF19DFFF), // cyan
    Color(0xFF31E85F), // green
    Color(0xFFFFD735), // yellow
    Color(0xFFFF861E), // orange
    Color(0xFFFF334A), // red
    Color(0xFF9E45FF), // purple
  ];

  static LinearGradient pieceGradient(int index) {
    final Color base = piecePalette[index % piecePalette.length];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Color.lerp(base, Colors.white, .82)!,
        Color.lerp(base, Colors.white, .38)!,
        base,
        Color.lerp(base, Colors.black, .18)!,
        Color.lerp(base, Colors.black, .50)!,
      ],
      stops: const <double>[0, .16, .46, .76, 1],
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
        stops: <double>[0, .50, 1],
      );

  static LinearGradient get boardGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFF123B93),
          gameBoard,
          Color(0xFF061944),
          gameBoardDeep,
        ],
        stops: <double>[0, .34, .74, 1],
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
