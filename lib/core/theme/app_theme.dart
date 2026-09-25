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

  // A still indigo-to-violet stage, with a darker board so saturated pieces
  // read clearly on a small phone without needing a moving background.
  static const Color gameBackgroundTop = Color(0xFF443795);
  static const Color gameBackgroundMid = Color(0xFF344184);
  static const Color gameBackgroundBottom = Color(0xFF202B58);
  static const Color gameBoard = Color(0xFF122043);
  static const Color gameBoardDeep = Color(0xFF080F29);
  static const Color gameCell = Color(0xFF2B426C);
  static const Color gameCellEdge = Color(0xFF7892BF);
  static const Color gameText = Color(0xFFFFFFFF);
  static const Color gameTextMuted = Color(0xFFE2E8FF);
  static const Color gameOverlay = Color(0xDC071330);
  static const Color rewardGold = Color(0xFFFFDB70);
  static const Color rewardCyan = Color(0xFF75ECF1);
  static const Color rewardCoral = Color(0xFFFF8CA0);
  static const Color rewardViolet = Color(0xFFD7B0FF);

  // Bright, clearly distinguishable puzzle colors. The engine stores only
  // palette indices; presentation owns the actual color system.
  static const List<Color> piecePalette = <Color>[
    Color(0xFF59AEFF), // sky blue
    Color(0xFF28D7DE), // aqua
    Color(0xFF42D98E), // mint
    Color(0xFFFFD45A), // golden yellow
    Color(0xFFFF9D58), // tangerine
    Color(0xFFF76B92), // rose
    Color(0xFFB78BFA), // lavender
  ];

  static LinearGradient pieceGradient(int index) {
    final Color base = piecePalette[index % piecePalette.length];
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Color.lerp(base, Colors.white, .13)!,
        base,
        Color.lerp(base, Colors.black, .16)!,
      ],
      stops: const <double>[0, .45, 1],
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

  /// Keep the playfield's color stable throughout a run. Rewards animate only
  /// their numbers; a changing background competes with the next move.
  static LinearGradient gameplayGradientForScore(int score) {
    return gameBackgroundGradient;
  }

  static LinearGradient get boardGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xFF3F3A8D),
          gameBoard,
          Color(0xFF172C61),
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
