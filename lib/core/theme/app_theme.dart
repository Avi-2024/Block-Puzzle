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

  // A quiet midnight-blue stage keeps the bright pieces and rewards legible.
  static const Color gameBackgroundTop = Color(0xFF304773);
  static const Color gameBackgroundMid = Color(0xFF283B65);
  static const Color gameBackgroundBottom = Color(0xFF1B2B4D);
  static const Color gameBoard = Color(0xFF132442);
  static const Color gameBoardDeep = Color(0xFF020819);
  static const Color gameCell = Color(0xFF253957);
  static const Color gameCellEdge = Color(0xFF536D96);
  static const Color gameText = Color(0xFFFFFFFF);
  static const Color gameTextMuted = Color(0xFFD9E7FF);
  static const Color gameOverlay = Color(0xDC071330);
  static const Color rewardGold = Color(0xFFFFDC77);
  static const Color rewardCyan = Color(0xFF6BE5F2);
  static const Color rewardCoral = Color(0xFFFF8395);
  static const Color rewardViolet = Color(0xFFC69AFF);

  // Bright, clearly distinguishable puzzle colors. The engine stores only
  // palette indices; presentation owns the actual color system.
  static const List<Color> piecePalette = <Color>[
    Color(0xFF399FEF), // blue
    Color(0xFF26C7DC), // cyan
    Color(0xFF39CC77), // green
    Color(0xFFF6CC4F), // yellow
    Color(0xFFF59348), // orange
    Color(0xFFEE5D71), // coral
    Color(0xFFA871EC), // violet
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

  /// A small Blockiva-owned set of moods. The score selects the stage, so a
  /// resumed run always returns to the same colors without stored UI state.
  static LinearGradient gameplayGradientForScore(int score) {
    final List<Color> colors = switch ((score ~/ 1000) % 3) {
      1 => const <Color>[
        Color(0xFF454273), Color(0xFF35315F), Color(0xFF211F46),
      ],
      2 => const <Color>[
        Color(0xFF296177), Color(0xFF24506A), Color(0xFF1A324D),
      ],
      _ => const <Color>[
        gameBackgroundTop, gameBackgroundMid, gameBackgroundBottom,
      ],
    };
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
      stops: const <double>[0, .50, 1],
    );
  }

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
