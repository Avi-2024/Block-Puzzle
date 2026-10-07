import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/puzzle.dart';
import '../game/puzzle_store.dart';
import 'puzzle_painters.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.engine,
    required this.initialState,
    this.store,
    this.autoPlay = false,
  });
  final PuzzleEngine engine;
  final PuzzleState initialState;
  final PuzzleStore? store;
  final bool autoPlay;
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late PuzzleState _state;
  late final AnimationController _fx, _flight, _refill;
  final _boardKey = GlobalKey(), _rootKey = GlobalKey();
  final _slotKeys = List.generate(3, (_) => GlobalKey());
  PuzzleMove? _move;
  Piece? _floatingPiece;
  int? _dragSlot, _selected, _ghostX, _ghostY;
  Offset? _floatingGlobal;
  Offset _flightFrom = Offset.zero, _flightTo = Offset.zero;
  Timer? _settleTimer, _outcomeTimer;
  bool _busy = false,
      _active = true,
      _gameOver = false,
      _reduce = false,
      _haptics = true;
  bool _demo = false, _demoPlaying = false, _newBest = false;
  int _demoToken = 0, _shownFrom = 0;
  PuzzleState? _savedPlayState;
  PointerDeviceKind _pointer = PointerDeviceKind.touch;
  String _status = 'Find your next move';
  bool get _reduced => _reduce || MediaQuery.disableAnimationsOf(context);
  bool get _input => _active && !_busy && !_gameOver && !_demoPlaying;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _state = widget.initialState;
    _shownFrom = _state.score;
    _haptics = widget.store?.haptics ?? true;
    _reduce = widget.store?.reduceMotion ?? false;
    _fx = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1750),
      value: 1,
    );
    _refill = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
      value: 1,
    );
    _flight =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 160),
        )..addListener(() {
          if (mounted) {
            setState(() {
              _floatingGlobal = Offset.lerp(
                _flightFrom,
                _flightTo,
                Curves.easeInOutCubic.transform(_flight.value),
              );
            });
          }
        });
    _gameOver = _state.gameOver;
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(seconds: 3));
        if (mounted && _active) unawaited(_playDemo());
      });
    }
  }

  @override
  void dispose() {
    _demoToken++;
    _settleTimer?.cancel();
    _outcomeTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _fx.dispose();
    _flight.dispose();
    _refill.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (!_active) {
      _settleTimer?.cancel();
      _outcomeTimer?.cancel();
      _flight.stop(canceled: true);
      _fx.value = 1;
      _dragSlot = null;
      _floatingPiece = null;
      _floatingGlobal = null;
      _ghostX = null;
      _ghostY = null;
      _selected = null;
      _busy = false;
      if (_demo) _exitDemo();
    }
    if (mounted) {
      setState(() {
        _gameOver = _state.gameOver;
      });
    }
  }

  RenderBox? _box(GlobalKey key) =>
      key.currentContext?.findRenderObject() as RenderBox?;
  Rect? get _boardRect {
    final box = _box(_boardKey);
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  double get _unit => (_boardRect?.width ?? 320) * 38 / 320;
  Offset _pieceTopLeft(Piece piece, Offset pointer) {
    final lift = _pointer == PointerDeviceKind.touch ? 54.0 : 12.0;
    return pointer -
        Offset(piece.width * _unit / 2, piece.height * _unit / 2 + lift);
  }

  void _previewAt(Offset topLeft) {
    final rect = _boardRect, piece = _floatingPiece;
    _ghostX = null;
    _ghostY = null;
    if (rect == null || piece == null) return;
    final pad = rect.width * 8 / 320,
        x = ((topLeft.dx - rect.left - pad) / _unit).round(),
        y = ((topLeft.dy - rect.top - pad) / _unit).round();
    if (canPlace(_state.board, piece, x, y)) {
      _ghostX = x;
      _ghostY = y;
    }
  }

  void _beginDrag(int slot, DragStartDetails details) {
    if (!_input || _dragSlot != null || _state.tray[slot] == null) return;
    _flight.stop(canceled: true);
    setState(() {
      _dragSlot = slot;
      _selected = null;
      _floatingPiece = _state.tray[slot];
      _floatingGlobal = _pieceTopLeft(_floatingPiece!, details.globalPosition);
      _previewAt(_floatingGlobal!);
    });
    if (_haptics) unawaited(HapticFeedback.selectionClick());
  }

  void _updateDrag(int slot, DragUpdateDetails details) {
    if (_dragSlot != slot || _floatingPiece == null || !_input) return;
    setState(() {
      _floatingGlobal = _pieceTopLeft(_floatingPiece!, details.globalPosition);
      _previewAt(_floatingGlobal!);
    });
  }

  Future<void> _returnPiece() async {
    final slot = _dragSlot, piece = _floatingPiece, rect = _boardRect;
    if (slot == null || piece == null || rect == null) {
      _clearDrag();
      return;
    }
    final box = _box(_slotKeys[slot]);
    if (box == null) {
      _clearDrag();
      return;
    }
    _flightFrom = _floatingGlobal!;
    _flightTo =
        box.localToGlobal(box.size.center(Offset.zero)) -
        Offset(piece.width * _unit / 2, piece.height * _unit / 2);
    setState(() {
      _ghostX = null;
      _ghostY = null;
    });
    if (!_reduced) {
      _flight.duration = const Duration(milliseconds: 160);
      try {
        await _flight.forward(from: 0).orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (mounted) _clearDrag();
  }

  void _clearDrag() {
    if (mounted) {
      setState(() {
        _dragSlot = null;
        _floatingPiece = null;
        _floatingGlobal = null;
        _ghostX = null;
        _ghostY = null;
      });
    }
  }

  void _endDrag(int slot, DragEndDetails details) {
    if (_dragSlot != slot) return;
    if (_ghostX != null && _ghostY != null && _input) {
      _commit(_dragSlot!, _ghostX!, _ghostY!);
    } else {
      unawaited(_returnPiece());
    }
  }

  void _select(int slot) {
    if (!_input || _dragSlot != null || _state.tray[slot] == null) return;
    setState(() {
      _selected = _selected == slot ? null : slot;
      _status = _selected == null
          ? 'Find your next move'
          : 'Tap a cell to place';
    });
  }

  void _tapBoard(TapUpDetails details) {
    if (!_input || _selected == null) return;
    final rect = _boardRect;
    if (rect == null) return;
    final p = details.localPosition, pad = rect.width * 8 / 320;
    final x = ((p.dx - pad) / _unit).floor(),
        y = ((p.dy - pad) / _unit).floor();
    if (!_commit(_selected!, x, y)) {
      setState(() {
        _status = 'That space is occupied';
      });
    }
  }

  bool _commit(int slot, int x, int y) {
    var result = widget.engine.place(_state, slot, x, y);
    if (result == null) return false;
    final old = _state, refill = old.tray.whereType<Piece>().length == 1;
    if (_demo && refill) {
      final state = result.state;
      result = PuzzleMove(
        state: PuzzleState(
          board: state.board,
          tray: const [Piece(3, 3), Piece(10, 1), Piece(6, 0)],
          score: state.score,
          best: state.best,
          combo: state.combo,
          moves: state.moves,
        ),
        beforeClear: result.beforeClear,
        placed: result.placed,
        cleared: result.cleared,
        rows: result.rows,
        columns: result.columns,
        points: result.points,
      );
    }
    _settleTimer?.cancel();
    _outcomeTimer?.cancel();
    setState(() {
      _shownFrom = old.score;
      _state = result!.state;
      _move = result;
      _newBest = _state.score > old.best;
      _busy = result.lines > 0;
      _selected = null;
      _dragSlot = null;
      _floatingGlobal = null;
      _floatingPiece = null;
      _ghostX = null;
      _ghostY = null;
      _status = result.lines > 0
          ? '${RewardStyle.forMove(result).title} · +${result.points}'
          : '+${result.points} · Nice placement';
    });
    _fx.forward(from: 0);
    if (refill) _refill.forward(from: 0);
    if (_haptics && _active) {
      unawaited(
        result.lines > 0
            ? HapticFeedback.mediumImpact()
            : HapticFeedback.lightImpact(),
      );
    }
    if (!_demo) _persist();
    if (_busy) {
      _settleTimer = Timer(Duration(milliseconds: _reduced ? 100 : 420), () {
        if (mounted) {
          setState(() {
            _busy = false;
          });
        }
      });
    }
    if (_state.gameOver) {
      _outcomeTimer = Timer(
        Duration(milliseconds: result.lines > 0 ? 1800 : 500),
        () {
          if (mounted && _active) {
            setState(() {
              _gameOver = true;
            });
          }
        },
      );
    }
    return true;
  }

  void _persist() {
    unawaited(
      widget.store?.save(_state).catchError((Object error) {
            if (mounted) {
              setState(() {
                _status = 'Progress could not be saved';
              });
            }
          }) ??
          Future<void>.value(),
    );
  }

  void _resetState(PuzzleState state) {
    _settleTimer?.cancel();
    _outcomeTimer?.cancel();
    _flight.stop(canceled: true);
    _fx.value = 1;
    _refill.value = 1;
    setState(() {
      _state = state;
      _shownFrom = state.score;
      _move = null;
      _busy = false;
      _gameOver = state.gameOver;
      _newBest = false;
      _dragSlot = null;
      _selected = null;
      _floatingGlobal = null;
      _floatingPiece = null;
      _ghostX = null;
      _ghostY = null;
      _status = 'Find your next move';
    });
  }

  void _exitDemo() {
    _demoToken++;
    _demo = false;
    _demoPlaying = false;
    final state = _savedPlayState ?? widget.initialState;
    _savedPlayState = null;
    _resetState(state);
  }

  Future<void> _newGame() async {
    if (_demo) {
      _exitDemo();
      return;
    }
    if (_state.moves > 0 && !_gameOver) {
      final yes = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF173758),
          title: const Text('Start a new game?'),
          content: const Text('Your best score will be kept.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep playing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('New game'),
            ),
          ],
        ),
      );
      if (yes != true || !mounted) return;
    }
    _resetState(widget.engine.fresh(best: _state.best));
    _persist();
  }

  Future<bool> _pause(int milliseconds, int token) async {
    await Future<void>.delayed(Duration(milliseconds: milliseconds));
    return mounted && _active && _demoToken == token;
  }

  Future<bool> _demoPlacement(int slot, int x, int y, int token) async {
    final board = _boardRect,
        box = _box(_slotKeys[slot]),
        piece = _state.tray[slot];
    if (board == null || box == null || piece == null) return false;
    _flightFrom =
        box.localToGlobal(box.size.center(Offset.zero)) -
        Offset(piece.width * _unit / 2, piece.height * _unit / 2);
    _flightTo =
        board.topLeft +
        Offset(
          board.width * 8 / 320 + x * _unit,
          board.width * 8 / 320 + y * _unit,
        );
    setState(() {
      _dragSlot = slot;
      _floatingPiece = piece;
      _floatingGlobal = _flightFrom;
      _ghostX = x;
      _ghostY = y;
    });
    _flight.duration = Duration(milliseconds: _reduced ? 1 : 560);
    try {
      await _flight.forward(from: 0).orCancel;
    } on TickerCanceled {
      return false;
    }
    if (!await _pause(160, token)) return false;
    return _commit(slot, x, y);
  }

  Future<void> _playDemo() async {
    if (_demoPlaying) return;
    if (!_demo) _savedPlayState = _state;
    _demo = true;
    _demoPlaying = true;
    final token = ++_demoToken;
    _resetState(reviewScene());
    for (final move in const [(0, 2, 2), (1, 6, 3), (2, 2, 5), (0, 3, 7)]) {
      if (!await _pause(350, token)) return;
      if (!await _demoPlacement(move.$1, move.$2, move.$3, token)) return;
      if (!await _pause(1400, token)) return;
    }
    if (!await _pause(450, token)) return;
    setState(() {
      _demoPlaying = false;
      _status = 'All clear · New best 2,620';
    });
  }

  Future<void> _settings() async {
    _clearDrag();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF153456),
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, updateSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text(
                    'Settings',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Haptics'),
                  value: _haptics,
                  onChanged: (value) {
                    setState(() => _haptics = value);
                    updateSheet(() {});
                    unawaited(
                      widget.store?.setHaptics(value) ?? Future<void>.value(),
                    );
                  },
                ),
                SwitchListTile(
                  title: const Text('Reduce motion'),
                  subtitle: Text(
                    MediaQuery.disableAnimationsOf(context)
                        ? 'Your device also limits motion'
                        : 'Keep feedback gentle',
                  ),
                  value: _reduce,
                  onChanged: (value) {
                    setState(() => _reduce = value);
                    updateSheet(() {});
                    unawaited(
                      widget.store?.setReduceMotion(value) ??
                          Future<void>.value(),
                    );
                  },
                ),
                const Divider(color: Color(0x22FFFFFF)),
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: const Text('Preview combo animations'),
                  subtitle: const Text('Your current game will be kept'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    unawaited(_playDemo());
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text('Keep playing'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _mark() => Transform.rotate(
    angle: -.12,
    child: SizedBox(
      width: 22,
      height: 22,
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: [2, 1, 0, 4]
            .map(
              (c) => Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: puzzleColors[c],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            )
            .toList(),
      ),
    ),
  );
  Widget _scores(bool compact) => SizedBox(
    height: compact ? 58 : 74,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'SCORE',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.8,
                color: Color(0xFFB3C9E5),
                fontWeight: FontWeight.w600,
              ),
            ),
            TweenAnimationBuilder<double>(
              key: ValueKey(_state.moves),
              tween: Tween(
                begin: _shownFrom.toDouble(),
                end: _state.score.toDouble(),
              ),
              duration: Duration(milliseconds: _reduced ? 0 : 550),
              builder: (context, value, child) {
                final progress = _state.score == _shownFrom
                    ? 1.0
                    : ((value - _shownFrom) / (_state.score - _shownFrom))
                          .clamp(0.0, 1.0);
                return Transform.scale(
                  alignment: Alignment.centerLeft,
                  scale: _reduced
                      ? 1
                      : 1 + .055 * math.sin(math.min(1, progress * 1.7) * math.pi),
                  child: Text(
                    _number(value.round()),
                    semanticsLabel: 'Score ${_state.score}',
                    style: TextStyle(
                      fontSize: compact ? 34 : 43,
                      height: 1.15,
                      letterSpacing: -1.5,
                      fontWeight: FontWeight.w700,
                      color: progress < .7
                          ? const Color(0xFFFFF0C0)
                          : const Color(0xFFF5F8FF),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_outlined,
                    size: 14,
                    color: Color(0xFFE7C778),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _newBest ? 'NEW BEST' : 'BEST',
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      color: Color(0xFFB3C9E5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                _number(_state.best),
                style: TextStyle(
                  fontSize: compact ? 20 : 23,
                  fontWeight: FontWeight.w600,
                  color: _newBest
                      ? const Color(0xFFFFDFA0)
                      : const Color(0xFFDFEBFC),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  String _number(int value) => value.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]},',
  );
  Widget _tray(double width, double height) => SizedBox(
    height: height,
    width: width,
    child: Row(
      children: List.generate(3, (slot) {
        final piece = _state.tray[slot], hidden = _dragSlot == slot;
        final unit = math.min(24.0, (width / 3 - 12) / 5);
        return Expanded(
          child: Listener(
            onPointerDown: (event) => _pointer = event.kind,
            child: GestureDetector(
              key: ValueKey('piece-slot-$slot'),
              behavior: HitTestBehavior.opaque,
              onTap: () => _select(slot),
              onPanStart: (details) => _beginDrag(slot, details),
              onPanUpdate: (details) => _updateDrag(slot, details),
              onPanEnd: (details) => _endDrag(slot, details),
              onPanCancel: () {
                if (_dragSlot == slot) unawaited(_returnPiece());
              },
              child: Semantics(
                button: true,
                label: piece == null
                    ? 'Used piece slot ${slot + 1}'
                    : 'Piece ${slot + 1}, ${piece.width} wide, ${piece.height} high',
                selected: _selected == slot,
                child: SizedBox(
                  key: _slotKeys[slot],
                  height: height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: piece == null || hidden
                              ? const SizedBox.shrink()
                              : AnimatedBuilder(
                                  animation: _refill,
                                  builder: (context, child) {
                                    final t = _reduced
                                        ? 1.0
                                        : Curves.easeOutBack.transform(
                                            _refill.value,
                                          );
                                    return Transform.translate(
                                      offset: Offset(0, (1 - t) * 12),
                                      child: Transform.scale(
                                        scale: .85 + .15 * t,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: CustomPaint(
                                    size: Size(
                                      piece.width * unit,
                                      piece.height * unit,
                                    ),
                                    painter: PiecePainter(
                                      piece,
                                      opacity:
                                          _selected == null || _selected == slot
                                          ? 1
                                          : .55,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Container(
                        width: 22,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: _selected == slot
                              ? const Color(0xFFAAF0D8)
                              : piece == null
                              ? const Color(0x207798BE)
                              : const Color(0x35B5CBEA),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final rootBox = _box(_rootKey), floating = _floatingPiece;
    final local = _floatingGlobal == null || rootBox == null
        ? null
        : rootBox.globalToLocal(_floatingGlobal!);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2B5C94), Color(0xFF254F85), Color(0xFF19385F)],
            stops: [0, .28, 1],
          ),
        ),
        child: SafeArea(
          child: Stack(
            key: _rootKey,
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxHeight < 650,
                          horizontal = compact ? 16.0 : 20.0;
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          compact ? 6 : 12,
                          horizontal,
                          4,
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 44,
                              child: Row(
                                children: [
                                  _mark(),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'BLOCK PUZZLE',
                                      maxLines: 1,
                                      style: TextStyle(
                                        fontSize: compact ? 14 : 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Settings',
                                    onPressed: _demoPlaying ? null : _settings,
                                    icon: const Icon(
                                      Icons.tune_rounded,
                                      size: 22,
                                      color: Color(0xFFCFDDF1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: compact ? 2 : 14),
                            _scores(compact),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, space) {
                                  final trayHeight = compact ? 76.0 : 108.0,
                                      hintHeight = compact ? 16.0 : 20.0,
                                      metaHeight = compact ? 22.0 : 30.0;
                                  final boardSize = math.max(
                                    80.0,
                                    math.min(
                                      space.maxWidth,
                                      space.maxHeight -
                                          trayHeight -
                                          hintHeight -
                                          metaHeight,
                                    ),
                                  );
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: boardSize,
                                        height: metaHeight,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Semantics(
                                                liveRegion: true,
                                                child: Text(
                                                  _status,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFFB9CEE8),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              'CLASSIC',
                                              style: TextStyle(
                                                fontSize: 11,
                                                letterSpacing: 1.5,
                                                color: Color(0xFFB9CEE8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      RepaintBoundary(
                                        child: GestureDetector(
                                          onTapUp: _tapBoard,
                                          child: SizedBox(
                                            key: _boardKey,
                                            width: boardSize,
                                            height: boardSize,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    boardSize * 15 / 320,
                                                  ),
                                              child: CustomPaint(
                                                key: const ValueKey(
                                                  'puzzle-board',
                                                ),
                                                painter: PuzzleBoardPainter(
                                                  board: _state.board,
                                                  animation: _fx,
                                                  reduceMotion: _reduced,
                                                  move: _move,
                                                  ghost: _ghostX == null
                                                      ? null
                                                      : _floatingPiece,
                                                  ghostX: _ghostX ?? 0,
                                                  ghostY: _ghostY ?? 0,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      _tray(space.maxWidth, trayHeight),
                                      SizedBox(
                                        height: hintHeight,
                                        child: const Text(
                                          'Fill a row or column to clear it',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFFBACCE5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            SizedBox(
                              height: 44,
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: _newGame,
                                icon: Icon(
                                  _demo
                                      ? Icons.arrow_back_rounded
                                      : Icons.refresh_rounded,
                                  size: 17,
                                ),
                                label: Text(
                                  _demo ? 'Back to game' : 'New game',
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFFBDD0E8),
                                  textStyle: const TextStyle(fontSize: 12, fontFamily: 'Roboto'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (local != null && floating != null)
                Positioned(
                  left: local.dx,
                  top: local.dy,
                  child: IgnorePointer(
                    child: CustomPaint(
                      size: Size(
                        floating.width * _unit,
                        floating.height * _unit,
                      ),
                      painter: PiecePainter(floating),
                    ),
                  ),
                ),
              if (_gameOver)
                Positioned.fill(
                  child: ColoredBox(
                    color: const Color(0xAD0C2542),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Material(
                          color: const Color(0xFF193C61),
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.grid_view_rounded,
                                  size: 32,
                                  color: Color(0xFF8AD7BB),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'No more moves',
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You scored ${_number(_state.score)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFFCBDCF1),
                                  ),
                                ),
                                const SizedBox(height: 22),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: _newGame,
                                    child: const Text('Play again'),
                                  ),
                                ),
                              ],
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
      ),
    );
  }
}
