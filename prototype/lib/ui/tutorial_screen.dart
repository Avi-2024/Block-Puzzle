import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/puzzle.dart';
import 'puzzle_painters.dart';
import 'puzzle_theme.dart';

/// A separate practice round: never writes a board, best score, or session.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({
    super.key,
    required this.onComplete,
    this.reduceMotion = false,
    this.replay = false,
  });
  final VoidCallback onComplete;
  final bool reduceMotion, replay;
  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _engine = PuzzleEngine();
  late final AnimationController _fx;
  late PuzzleState _practice;
  PuzzleMove? _move;
  int _step = 0, _score = 0;
  bool _placed = false, _selected = false, _active = true;
  int get _x => const [2, 3, 4][_step];
  int get _y => const [5, 6, 5][_step];
  Piece get _piece => Piece(2, const [1, 0, 2][_step]);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fx = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1750),
      value: 1,
    );
    _setScene();
  }

  void _setScene() {
    final board = List<int>.filled(64, -1);
    if (_step == 0) {
      for (final i in [40, 48, 49]) {
        board[i] = 4;
      }
      for (final i in [54, 55, 62, 63]) {
        board[i] = 0;
      }
    } else {
      for (var x = 0; x < 8; x++) {
        if (x < _x || x >= _x + 3) board[_y * 8 + x] = _step == 1 ? 0 : 2;
      }
      board[56] = 4;
      board[57] = 4;
      board[63] = 1;
    }
    _practice = PuzzleState(
      board: board,
      tray: [_piece, null, null],
      score: _score,
      combo: _step == 2 ? 1 : 0,
    );
    _move = null;
    _placed = false;
    _selected = false;
    _fx.value = 1;
  }

  void _place() {
    if (_placed || !_active) return;
    final result = _engine.place(_practice, 0, _x, _y)!;
    setState(() {
      _practice = result.state;
      _move = result;
      _score = result.state.score;
      _placed = true;
      _selected = false;
    });
    _fx.forward(from: 0);
  }

  void _next() {
    if (!_placed) return;
    if (_step == 2) {
      widget.onComplete();
      return;
    }
    setState(() {
      _step++;
      _setScene();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (!_active) {
      _fx.value = 1;
      setState(() => _selected = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fx.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = PuzzleTheme.of(context);
    final reduced =
        widget.reduceMotion || MediaQuery.disableAnimationsOf(context);
    final title = const [
      'Find the perfect fit.',
      'Make a little room.',
      'Keep the good moves going.',
    ][_step];
    final instruction = const [
      'Drag the mint block into the glowing spaces.',
      'Fill the gap. A complete row clears space.',
      'Clear another line to build your combo.',
    ][_step];
    return GameSurface(
      child: LayoutBuilder(
        builder: (context, bounds) {
          final compact = bounds.maxHeight < 650;
          final boardSize = math.min(
            bounds.maxWidth - 48,
            compact ? 240.0 : 330.0,
          );
          final unit = boardSize * 38 / 320, pad = boardSize * 8 / 320;
          final tile = SizedBox(
            width: unit * 3,
            height: unit,
            child: CustomPaint(painter: PiecePainter(_piece, palette: p)),
          );
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const TiloraBrand(),
                      const Spacer(),
                      TextButton(
                        onPressed: widget.onComplete,
                        child: Text(
                          widget.replay ? 'Close guide' : 'Skip intro',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 10 : 24),
                  Text(
                    'A few good moves',
                    style: TextStyle(
                      color: p.muted,
                      fontSize: 12,
                      letterSpacing: .4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Expanded(
                          child: Container(
                            height: 3,
                            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                            decoration: BoxDecoration(
                              color: i <= _step ? p.accent : p.line,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: compact ? 16 : 26),
                  Text(
                    '${_step + 1} / 3   ${const ['DRAG', 'CLEAR', 'COMBO'][_step]}',
                    style: TextStyle(
                      color: p.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: TextStyle(
                      color: p.ink,
                      fontSize: compact ? 24 : 28,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.6,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    instruction,
                    style: TextStyle(color: p.muted, fontSize: 13, height: 1.5),
                  ),
                  SizedBox(height: compact ? 16 : 24),
                  Center(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'PRACTICE',
                                style: TextStyle(
                                  color: p.muted,
                                  fontSize: 9,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                formatScore(_score),
                                semanticsLabel: 'Practice score $_score',
                                style: TextStyle(
                                  color: p.ink,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: boardSize,
                          height: boardSize,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: PuzzleBoardPainter(
                                    board: _practice.board,
                                    animation: _fx,
                                    reduceMotion: reduced,
                                    move: _move,
                                    palette: p,
                                    ghost: _placed ? null : _piece,
                                    ghostX: _x,
                                    ghostY: _y,
                                  ),
                                ),
                              ),
                              if (!_placed)
                                Positioned(
                                  left: pad + _x * unit,
                                  top: pad + _y * unit,
                                  width: unit * 3,
                                  height: unit,
                                  child: DragTarget<int>(
                                    onWillAcceptWithDetails: (details) =>
                                        _active && details.data == _step,
                                    onAcceptWithDetails: (_) => _place(),
                                    builder: (context, accepted, rejected) =>
                                        Semantics(
                                          button: true,
                                          enabled: _selected,
                                          label:
                                              'Highlighted spaces. Place selected block',
                                          child: GestureDetector(
                                            key: const ValueKey(
                                              'tutorial-target',
                                            ),
                                            behavior: HitTestBehavior.opaque,
                                            onTap: _selected ? _place : null,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                                border: Border.all(
                                                  color: p.accent.withValues(
                                                    alpha:
                                                        _selected ||
                                                            accepted.isNotEmpty
                                                        ? 1
                                                        : .55,
                                                  ),
                                                  width: 1.5,
                                                ),
                                                color: p.accent.withValues(
                                                  alpha: accepted.isNotEmpty
                                                      ? .18
                                                      : .04,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: compact ? 14 : 20),
                        SizedBox(
                          height: math.max(48, unit + 8),
                          child: Center(
                            child: _placed
                                ? Semantics(
                                    liveRegion: true,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline_rounded,
                                          color: p.accent,
                                          size: 19,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          const [
                                            'Perfect fit. +30',
                                            'A clear space. +110',
                                            'That’s a combo! +190',
                                          ][_step],
                                          style: TextStyle(
                                            color: p.ink,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Draggable<int>(
                                    data: _step,
                                    maxSimultaneousDrags: _active ? 1 : 0,
                                    feedback: Material(
                                      color: Colors.transparent,
                                      child: tile,
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: .2,
                                      child: tile,
                                    ),
                                    child: Semantics(
                                      button: true,
                                      selected: _selected,
                                      label:
                                          'Practice block, three squares wide',
                                      child: GestureDetector(
                                        key: const ValueKey('tutorial-piece'),
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () =>
                                            setState(() => _selected = true),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          child: tile,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Text(
                          _placed
                              ? 'One good move leads to another.'
                              : _selected
                              ? 'Now tap the glowing spaces.'
                              : 'Or tap the block, then the glowing spaces.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: compact ? 18 : 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const ValueKey('tutorial-next'),
                      onPressed: _placed ? _next : null,
                      child: Text(
                        _step == 2
                            ? (widget.replay ? 'Back to game' : 'Start playing')
                            : 'Continue',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
