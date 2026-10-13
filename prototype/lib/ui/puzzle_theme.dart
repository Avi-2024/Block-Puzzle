import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Magic Blocks palettes. Block indices stay stable across saved games.
class PuzzlePalette {
  const PuzzlePalette({
    required this.id,
    required this.name,
    required this.description,
    required this.background,
    required this.end,
    required this.panel,
    required this.cell,
    required this.ink,
    required this.muted,
    required this.line,
    required this.accent,
    required this.button,
    required this.buttonInk,
    required this.colors,
    this.middle,
    this.highlights,
    this.shadows,
    this.leftEdges,
    this.rightEdges,
    this.light = false,
  });
  final String id, name, description;
  final Color background,
      end,
      panel,
      cell,
      ink,
      muted,
      line,
      accent,
      button,
      buttonInk;
  final List<Color> colors;
  final List<Color>? highlights, shadows, leftEdges, rightEdges;
  final Color? middle;
  final bool light;
  static const ocean = PuzzlePalette(
    id: 'ocean',
    name: 'Ocean',
    description: 'A calm blue. Room to think.',
    background: Color(0xFF173A60),
    middle: Color(0xFF102C48),
    end: Color(0xFF0B2138),
    panel: Color(0xFF15344F),
    cell: Color(0xFF203E5C),
    ink: Color(0xFFF3F7FF),
    muted: Color(0xFFBCCFE4),
    line: Color(0xFF426487),
    accent: Color(0xFFF8D58A),
    button: Color(0xFFF8D58A),
    buttonInk: Color(0xFF223C55),
    colors: [
      Color(0xFF3B5DE2), // blue
      Color(0xFF30B43A), // green
      Color(0xFFE6AE32), // gold
      Color(0xFFC73032), // red
      Color(0xFF8853D3), // purple
      Color(0xFFE56F1F), // orange
      Color(0xFF29B0E0), // cyan
    ],
    highlights: [
      Color(0xFF8EB5FF), Color(0xFF83F19B), Color(0xFFFAE577),
      Color(0xFFEF8686), Color(0xFFD597F0), Color(0xFFFFBE81), Color(0xFF97E9FE),
    ],
    shadows: [
      Color(0xFF21358C), Color(0xFF0E711D), Color(0xFFAF7216),
      Color(0xFF851E25), Color(0xFF5A2682), Color(0xFF9C4609), Color(0xFF066EA5),
    ],
    leftEdges: [
      Color(0xFF4466F2), Color(0xFF42C73F), Color(0xFFF8C83B),
      Color(0xFFD94345), Color(0xFFA066D8), Color(0xFFFD8B37), Color(0xFF3DC0ED),
    ],
    rightEdges: [
      Color(0xFF284CC4), Color(0xFF0D882F), Color(0xFFCB951B),
      Color(0xFFAF2825), Color(0xFF7039A0), Color(0xFFC25E17), Color(0xFF1992CC),
    ],
  );
  static const midnight = PuzzlePalette(
    id: 'midnight',
    name: 'Midnight',
    description: 'Quiet focus, after hours.',
    background: Color(0xFF1C233C),
    end: Color(0xFF101527),
    panel: Color(0xFF101729),
    cell: Color(0xFF29324C),
    ink: Color(0xFFF0F1FF),
    muted: Color(0xFFBDC5DF),
    line: Color(0xFF414965),
    accent: Color(0xFFD4C0FF),
    button: Color(0xFFD4C0FF),
    buttonInk: Color(0xFF292139),
    colors: [
      Color(0xFF779AE3),
      Color(0xFF70C6B4),
      Color(0xFFE5BF7B),
      Color(0xFFDB93A9),
      Color(0xFFB5A0ED),
      Color(0xFFE7A05B),
      Color(0xFF55BAD8),
    ],
  );
  static const sand = PuzzlePalette(
    id: 'sand',
    name: 'Warm Sand',
    description: 'A softer, sunlit kind of play.',
    light: true,
    background: Color(0xFFF4EAD9),
    end: Color(0xFFE7D7BD),
    panel: Color(0xFFB9A183),
    cell: Color(0xFFE0CEB1),
    ink: Color(0xFF342D27),
    muted: Color(0xFF6E5B48),
    line: Color(0xFFC5AE91),
    accent: Color(0xFF8B531F),
    button: Color(0xFF315E50),
    buttonInk: Color(0xFFFFF9ED),
    colors: [
      Color(0xFF5489A8),
      Color(0xFF438B76),
      Color(0xFFC99539),
      Color(0xFFBB7461),
      Color(0xFF9977A9),
      Color(0xFFC47735),
      Color(0xFF347F99),
    ],
  );
  static const values = [ocean, midnight, sand];
  static PuzzlePalette fromId(String? id) =>
      values.firstWhere((p) => p.id == id, orElse: () => ocean);
  Color tileLight(int index) => highlights?[index] ?? Color.lerp(colors[index], Colors.white, .32)!;
  Color tileDark(int index) => shadows?[index] ?? Color.lerp(colors[index], Colors.black, .30)!;
  Color tileLeft(int index) => leftEdges?[index] ?? Color.lerp(colors[index], Colors.white, .16)!;
  Color tileRight(int index) => rightEdges?[index] ?? Color.lerp(colors[index], Colors.black, .16)!;
  LinearGradient get gradient => LinearGradient(
    begin: middle == null ? Alignment.topLeft : Alignment.topCenter,
    end: middle == null ? Alignment.bottomRight : Alignment.bottomCenter,
    colors: [background, ?middle, end],
    stops: middle == null ? null : const [0, .55, 1],
  );
  SystemUiOverlayStyle get systemStyle => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: light ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: end,
    systemNavigationBarIconBrightness: light
        ? Brightness.dark
        : Brightness.light,
  );
  ThemeData get themeData => ThemeData(
    brightness: light ? Brightness.light : Brightness.dark,
    fontFamily: 'Roboto',
    useMaterial3: true,
    scaffoldBackgroundColor: end,
    colorScheme: ColorScheme.fromSeed(
      seedColor: button,
      brightness: light ? Brightness.light : Brightness.dark,
      primary: button,
      onPrimary: buttonInk,
      surface: end,
      onSurface: ink,
    ),
    iconTheme: IconThemeData(color: muted),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 54),
        foregroundColor: buttonInk,
        backgroundColor: button,
        textStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: muted,
        minimumSize: const Size(48, 48),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ink,
      contentTextStyle: TextStyle(color: end),
    ),
  );
}

class PuzzleTheme extends InheritedWidget {
  const PuzzleTheme({
    super.key,
    required this.palette,
    required this.onChanged,
    required super.child,
  });
  final PuzzlePalette palette;
  final Future<void> Function(PuzzlePalette) onChanged;
  static PuzzleTheme? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PuzzleTheme>();
  static PuzzlePalette of(BuildContext context) =>
      maybeOf(context)?.palette ?? PuzzlePalette.ocean;
  @override
  bool updateShouldNotify(PuzzleTheme oldWidget) =>
      oldWidget.palette != palette;
}

class MagicBlocksMark extends StatelessWidget {
  const MagicBlocksMark({super.key, this.size = 28});
  final double size;
  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            _markTile(size, .34, .01, PuzzlePalette.ocean.colors[2]),
            _markTile(size, .01, .34, PuzzlePalette.ocean.colors[0]),
            _markTile(size, .67, .34, PuzzlePalette.ocean.colors[3]),
            _markTile(size, .34, .67, PuzzlePalette.ocean.colors[1]),
            Positioned.fill(
              child: Center(
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: size * .30,
                  color: const Color(0xFFFFF4B5),
                  shadows: const [
                    Shadow(color: Color(0xFFFFC83D), blurRadius: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _markTile(double size, double x, double y, Color color) => Positioned(
    left: size * x,
    top: size * y,
    child: Container(
      width: size * .32,
      height: size * .32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .037),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, .30)!,
            color,
            color,
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: .24),
          width: size * .009,
        ),
        boxShadow: [
          BoxShadow(
            color: Color.lerp(color, Colors.black, .24)!,
            blurRadius: size * .02,
            offset: Offset(0, size * .02),
          ),
        ],
      ),
    ),
  );
}

class MagicBlocksBrand extends StatelessWidget {
  const MagicBlocksBrand({super.key, this.palette});
  final PuzzlePalette? palette;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const MagicBlocksMark(),
      const SizedBox(width: 9),
      Text(
        'MAGIC BLOCKS',
        style: TextStyle(
          color: (palette ?? PuzzleTheme.of(context)).ink,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: .9,
        ),
      ),
    ],
  );
}

class GameSurface extends StatelessWidget {
  const GameSurface({super.key, required this.child, this.palette});
  final Widget child;
  final PuzzlePalette? palette;
  @override
  Widget build(BuildContext context) {
    final p = palette ?? PuzzleTheme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.systemStyle,
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(gradient: p.gradient),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String formatScore(int score) => score.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]},',
);

