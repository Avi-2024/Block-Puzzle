import 'package:flutter/material.dart';
import '../game/puzzle.dart';
import 'puzzle_painters.dart';
import 'puzzle_theme.dart';

Future<void> openThemes(BuildContext context) => Navigator.of(context).push<void>(
  MaterialPageRoute(builder: (_) => const ThemeScreen()));

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});
  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  PuzzlePalette? _draft;
  bool _saving = false;
  Future<void> _apply() async {
    setState(() => _saving = true);
    try {
      await PuzzleTheme.maybeOf(context)?.onChanged(_draft ?? PuzzleTheme.of(context));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Theme could not be saved. Please try again.')));
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final p = _draft ?? PuzzleTheme.of(context);
    return Theme(data: p.themeData, child: GameSurface(palette: p, child: LayoutBuilder(builder: (context, bounds) {
      final compact = bounds.maxHeight < 650;
      return SingleChildScrollView(child: Padding(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [TiloraBrand(palette: p), const Spacer(), IconButton(tooltip: 'Close themes', onPressed: _saving ? null : () => Navigator.pop(context), icon: const Icon(Icons.close_rounded))]),
          SizedBox(height: compact ? 8 : 28),
          Text('Make it your space.', style: TextStyle(color: p.ink, fontSize: compact ? 25 : 30, fontWeight: FontWeight.w700, letterSpacing: -.8)),
          const SizedBox(height: 8), Text('Same good moves. A different mood.', style: TextStyle(color: p.muted, fontSize: 14)),
          SizedBox(height: compact ? 14 : 24),
          Center(child: Column(children: [Text('1,280', style: TextStyle(color: p.ink, fontSize: 26, fontWeight: FontWeight.w700)), const SizedBox(height: 10),
            CustomPaint(key: const ValueKey('theme-preview-board'), size: Size.square(compact ? 150 : 208), painter: PuzzleBoardPainter(
              board: reviewScene().board, animation: const AlwaysStoppedAnimation(1), reduceMotion: true, palette: p))])),
          SizedBox(height: compact ? 14 : 24),
          for (final option in PuzzlePalette.values) Padding(padding: const EdgeInsets.only(bottom: 9), child: Semantics(selected: p == option,
            child: Material(color: p == option ? p.ink.withValues(alpha: .07) : Colors.transparent,
              shape: RoundedRectangleBorder(side: BorderSide(color: p == option ? p.accent : p.line.withValues(alpha: .6)), borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias, child: InkWell(key: ValueKey('theme-${option.id}'), onTap: _saving ? null : () => setState(() => _draft = option),
                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(children: [
                  Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: option.end, borderRadius: BorderRadius.circular(11)), child: TiloraMark(palette: option, size: 29)),
                  const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(option.name, style: TextStyle(color: p.ink, fontSize: 16, fontWeight: FontWeight.w700)), const SizedBox(height: 3),
                    Text(option.description, style: TextStyle(color: p.muted, fontSize: 12))])),
                  Icon(p == option ? Icons.check_circle_rounded : Icons.circle_outlined, color: p == option ? p.accent : p.muted, size: 21)]))))))),
          const SizedBox(height: 10), SizedBox(width: double.infinity, child: FilledButton(key: const ValueKey('apply-theme'), onPressed: _saving ? null : _apply,
            child: Text(_saving ? 'Saving…' : 'Use ${p.name}'))),
        ])));
    })));
  }
}
