import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../game/puzzle.dart';
import 'puzzle_theme.dart';
import 'theme_screen.dart';

String scoreShareText(PuzzleState state) => 'I scored ${formatScore(state.score)} in Tilora!\n'
  'Best: ${formatScore(state.best)} · Biggest combo: ×${state.maxCombo} · Lines cleared: ${state.linesCleared}\nA little focus. A few good moves.';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key, required this.state, required this.onPlayAgain, this.reduceMotion = false});
  final PuzzleState state;
  final VoidCallback onPlayAgain;
  final bool reduceMotion;
  @override
  Widget build(BuildContext context) {
    final p = PuzzleTheme.of(context);
    return GameSurface(child: LayoutBuilder(builder: (context, bounds) {
      final compact = bounds.maxHeight < 650;
      return Column(children: [Expanded(child: SingleChildScrollView(
        child: Padding(padding: const EdgeInsets.fromLTRB(26, 8, 26, 20), child: Column(children: [
          Row(children: [const TiloraBrand(), const Spacer(), IconButton(tooltip: 'Themes', onPressed: () => openThemes(context), icon: const Icon(Icons.palette_outlined))]),
          SizedBox(height: compact ? 16 : 36),
          Text('CLASSIC · ROUND COMPLETE', style: TextStyle(color: p.muted, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w600)),
          SizedBox(height: compact ? 20 : 32),
          TweenAnimationBuilder<double>(tween: Tween(begin: .85, end: 1), duration: Duration(milliseconds: reduceMotion || MediaQuery.disableAnimationsOf(context) ? 0 : 650),
            curve: Curves.easeOutBack, builder: (context, value, child) => Transform.scale(scale: value, child: child),
            child: SizedBox(height: compact ? 76 : 104, width: 150, child: Stack(alignment: Alignment.center, children: [
              Transform.rotate(angle: .785, child: Container(width: compact ? 60 : 76, height: compact ? 60 : 76,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: p.accent.withValues(alpha: .08), border: Border.all(color: p.accent.withValues(alpha: .25))))),
              Icon(Icons.emoji_events_outlined, color: p.accent, size: compact ? 44 : 56),
              Positioned(left: 6, top: 13, child: Icon(Icons.auto_awesome, size: 15, color: p.accent.withValues(alpha: .65))),
              Positioned(right: 7, bottom: 12, child: Icon(Icons.auto_awesome, size: 10, color: p.accent.withValues(alpha: .5)))]))),
          SizedBox(height: compact ? 18 : 28),
          Text('Beautifully played.', textAlign: TextAlign.center, style: TextStyle(color: p.ink, fontSize: compact ? 26 : 31, fontWeight: FontWeight.w700, letterSpacing: -.8)),
          const SizedBox(height: 8), Text(state.isNewRecord ? 'A little focus. A new personal best.' : 'Every round is a fresh possibility.', textAlign: TextAlign.center, style: TextStyle(color: p.muted, fontSize: 13)),
          SizedBox(height: compact ? 20 : 30),
          if (state.isNewRecord) Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: p.accent.withValues(alpha: .10), border: Border.all(color: p.accent.withValues(alpha: .25)), borderRadius: BorderRadius.circular(20)),
            child: Text('NEW PERSONAL BEST', style: TextStyle(color: p.accent, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.6)))
          else Text('YOUR SCORE', style: TextStyle(color: p.muted, letterSpacing: 2, fontSize: 10)),
          const SizedBox(height: 8), FittedBox(child: Text(formatScore(state.score), key: const ValueKey('result-score'), semanticsLabel: 'Final score ${state.score}',
            style: TextStyle(color: p.ink, fontSize: compact ? 58 : 76, height: 1.12, fontWeight: FontWeight.w700, letterSpacing: -3))),
          const SizedBox(height: 9), Text('Personal best  ${formatScore(state.best)}', style: TextStyle(color: p.muted, fontSize: 13)),
          SizedBox(height: compact ? 20 : 28),
          Container(padding: const EdgeInsets.symmetric(vertical: 19), decoration: BoxDecoration(color: p.panel.withValues(alpha: p.light ? .20 : .7), borderRadius: BorderRadius.circular(18), border: Border.all(color: p.line.withValues(alpha: .35))),
            child: IntrinsicHeight(child: Row(children: [Expanded(child: _stat(p, '×${state.maxCombo}', 'BIGGEST COMBO')),
              VerticalDivider(width: 1, color: p.line), Expanded(child: _stat(p, '${state.linesCleared}', 'LINES CLEARED'))]))),
        ])))),
        Padding(padding: const EdgeInsets.fromLTRB(26, 8, 26, 12), child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: double.infinity, child: FilledButton.icon(key: const ValueKey('play-again'), onPressed: onPlayAgain, icon: const Icon(Icons.refresh_rounded, size: 21), label: const Text('Play again'))),
          const SizedBox(height: 6), TextButton.icon(onPressed: () => showDialog<void>(context: context, builder: (_) => _ShareScoreDialog(state: state)), icon: const Icon(Icons.ios_share_rounded, size: 18), label: const Text('Share score')),
        ])),
      ]);
    }));
  }
  Widget _stat(PuzzlePalette p, String value, String label) => Column(children: [Text(value, style: TextStyle(color: p.ink, fontSize: 25, fontWeight: FontWeight.w700)),
    const SizedBox(height: 6), Text(label, style: TextStyle(color: p.muted, letterSpacing: 1, fontSize: 9))]);
}

class _ShareScoreDialog extends StatefulWidget {
  const _ShareScoreDialog({required this.state});
  final PuzzleState state;
  @override
  State<_ShareScoreDialog> createState() => _ShareScoreDialogState();
}
class _ShareScoreDialogState extends State<_ShareScoreDialog> {
  bool _busy = false;
  String? _notice;
  Future<void> _share() async {
    final box = context.findRenderObject() as RenderBox?;
    setState(() => _busy = true);
    try {
      final result = await SharePlus.instance.share(ShareParams(text: scoreShareText(widget.state), subject: 'My Tilora score',
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size));
      if (mounted && result.status == ShareResultStatus.unavailable) {
        setState(() => _notice = 'Sharing is unavailable here. You can copy your score instead.');
      }
    } catch (_) {
      if (mounted) setState(() => _notice = 'Could not open sharing. You can copy your score instead.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  Future<void> _copy() async {
    try {
      await Clipboard.setData(ClipboardData(text: scoreShareText(widget.state)));
      if (mounted) setState(() => _notice = 'Score copied');
    } catch (_) {
      if (mounted) setState(() => _notice = 'Could not copy. Please try again.');
    }
  }
  @override
  Widget build(BuildContext context) {
    final p = PuzzleTheme.of(context), s = widget.state;
    return AlertDialog(backgroundColor: p.end, title: Row(children: [const TiloraBrand(), const Spacer(), IconButton(tooltip: 'Close sharing', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded))]),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('A few good moves.', style: TextStyle(color: p.muted, fontSize: 14)), const SizedBox(height: 20),
        Text(formatScore(s.score), style: TextStyle(color: p.ink, fontSize: 44, fontWeight: FontWeight.w700, letterSpacing: -1)),
        const SizedBox(height: 8), Text('×${s.maxCombo} combo  ·  ${s.linesCleared} lines', style: TextStyle(color: p.muted)),
        const SizedBox(height: 22), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: _busy ? null : _share, icon: const Icon(Icons.ios_share_rounded, size: 18), label: Text(_busy ? 'Opening…' : 'Share score text'))),
        TextButton(onPressed: _copy, child: const Text('Copy score')),
        if (_notice != null) Semantics(liveRegion: true, child: Text(_notice!, textAlign: TextAlign.center, style: TextStyle(color: p.muted, fontSize: 12))),
      ])));
  }
}
