import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Original Tilora palettes. Block indices stay stable across saved games.
class PuzzlePalette {
  const PuzzlePalette({required this.id, required this.name, required this.description,
    required this.background, required this.end, required this.panel, required this.cell,
    required this.ink, required this.muted, required this.line, required this.accent,
    required this.button, required this.buttonInk, required this.colors, this.light = false});
  final String id, name, description;
  final Color background, end, panel, cell, ink, muted, line, accent, button, buttonInk;
  final List<Color> colors;
  final bool light;
  static const ocean = PuzzlePalette(
    id: 'ocean', name: 'Ocean', description: 'A calm blue. Room to think.',
    background: Color(0xFF254F7D), end: Color(0xFF183653), panel: Color(0xFF15344F),
    cell: Color(0xFF254868), ink: Color(0xFFF3F7FF), muted: Color(0xFFBCCFE4),
    line: Color(0xFF426487), accent: Color(0xFFF8D58A), button: Color(0xFFF8D58A),
    buttonInk: Color(0xFF223C55),
    colors: [Color(0xFF67A7E2), Color(0xFF68C2AA), Color(0xFFEDC16E), Color(0xFFE38F83), Color(0xFFAE9DDD)]);
  static const midnight = PuzzlePalette(
    id: 'midnight', name: 'Midnight', description: 'Quiet focus, after hours.',
    background: Color(0xFF1C233C), end: Color(0xFF101527), panel: Color(0xFF101729),
    cell: Color(0xFF29324C), ink: Color(0xFFF0F1FF), muted: Color(0xFFBDC5DF),
    line: Color(0xFF414965), accent: Color(0xFFD4C0FF), button: Color(0xFFD4C0FF),
    buttonInk: Color(0xFF292139),
    colors: [Color(0xFF779AE3), Color(0xFF70C6B4), Color(0xFFE5BF7B), Color(0xFFDB93A9), Color(0xFFB5A0ED)]);
  static const sand = PuzzlePalette(
    id: 'sand', name: 'Warm Sand', description: 'A softer, sunlit kind of play.', light: true,
    background: Color(0xFFF4EAD9), end: Color(0xFFE7D7BD), panel: Color(0xFFB9A183),
    cell: Color(0xFFE0CEB1), ink: Color(0xFF342D27), muted: Color(0xFF6E5B48),
    line: Color(0xFFC5AE91), accent: Color(0xFF8B531F), button: Color(0xFF315E50),
    buttonInk: Color(0xFFFFF9ED),
    colors: [Color(0xFF5489A8), Color(0xFF438B76), Color(0xFFC99539), Color(0xFFBB7461), Color(0xFF9977A9)]);
  static const values = [ocean, midnight, sand];
  static PuzzlePalette fromId(String? id) => values.firstWhere((p) => p.id == id, orElse: () => ocean);
  Color tileLight(int index) => Color.lerp(colors[index], Colors.white, .30)!;
  Color tileDark(int index) => Color.lerp(colors[index], Colors.black, .24)!;
  LinearGradient get gradient => LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [background, end]);
  SystemUiOverlayStyle get systemStyle => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: light ? Brightness.dark : Brightness.light,
    systemNavigationBarColor: end,
    systemNavigationBarIconBrightness: light ? Brightness.dark : Brightness.light);
  ThemeData get themeData => ThemeData(
    brightness: light ? Brightness.light : Brightness.dark,
    fontFamily: 'Roboto', useMaterial3: true,
    scaffoldBackgroundColor: end,
    colorScheme: ColorScheme.fromSeed(seedColor: button,
      brightness: light ? Brightness.light : Brightness.dark,
      primary: button, onPrimary: buttonInk, surface: end, onSurface: ink),
    iconTheme: IconThemeData(color: muted),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
      minimumSize: const Size(48, 54), foregroundColor: buttonInk, backgroundColor: button,
      textStyle: const TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w700),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)))),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: muted,
      minimumSize: const Size(48, 48))),
    snackBarTheme: SnackBarThemeData(backgroundColor: ink, contentTextStyle: TextStyle(color: end)));
}

class PuzzleTheme extends InheritedWidget {
  const PuzzleTheme({super.key, required this.palette, required this.onChanged, required super.child});
  final PuzzlePalette palette;
  final Future<void> Function(PuzzlePalette) onChanged;
  static PuzzleTheme? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<PuzzleTheme>();
  static PuzzlePalette of(BuildContext context) => maybeOf(context)?.palette ?? PuzzlePalette.ocean;
  @override
  bool updateShouldNotify(PuzzleTheme oldWidget) => oldWidget.palette != palette;
}

class TiloraMark extends StatelessWidget {
  const TiloraMark({super.key, this.size = 28, this.palette});
  final double size;
  final PuzzlePalette? palette;
  @override
  Widget build(BuildContext context) {
    final p = palette ?? PuzzleTheme.of(context), unit = size / 3;
    return ExcludeSemantics(child: Transform.rotate(angle: -.08, child: SizedBox(width: size, height: size,
      child: Stack(children: [for (final tile in const [(0, 0, 2), (1, 0, 2), (2, 0, 2), (1, 1, 1), (1, 2, 0)])
        Positioned(left: tile.$1 * unit, top: tile.$2 * unit, child: Container(width: unit - 2, height: unit - 2,
          decoration: BoxDecoration(color: p.colors[tile.$3], borderRadius: BorderRadius.circular(2))))]))));
  }
}

class TiloraBrand extends StatelessWidget {
  const TiloraBrand({super.key, this.palette});
  final PuzzlePalette? palette;
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    TiloraMark(palette: palette), const SizedBox(width: 10),
    Text('TILORA', style: TextStyle(color: (palette ?? PuzzleTheme.of(context)).ink,
      fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 2))]);
}

class GameSurface extends StatelessWidget {
  const GameSurface({super.key, required this.child, this.palette});
  final Widget child;
  final PuzzlePalette? palette;
  @override
  Widget build(BuildContext context) {
    final p = palette ?? PuzzleTheme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(value: p.systemStyle,
      child: Scaffold(body: DecoratedBox(decoration: BoxDecoration(gradient: p.gradient),
        child: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: child))))));
  }
}

String formatScore(int score) => score.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
