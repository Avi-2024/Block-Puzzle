import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/feedback/game_haptics.dart';
import '../../../core/widgets/blockiva_splash.dart';

import '../../../core/ads/ad_service.dart';
import '../../../core/audio/game_audio_service.dart';
import '../../../core/storage/game_stats_repository.dart';
import '../../../core/storage/shared_preferences_game_session_repository.dart';
import '../../../core/storage/shared_preferences_game_stats_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../daily_challenge/domain/daily_challenge_definition.dart';
import '../../daily_challenge/domain/daily_piece_generator.dart';
import '../../progression/application/progression_runtime.dart';
import '../../progression/presentation/progression_bootstrap.dart';
import '../application/game_session_controller.dart';
import '../domain/block_piece.dart';
import '../domain/game_engine.dart';
import '../domain/move_result.dart';
import 'board_drag_projector.dart';
import 'board_clear_effect.dart';
import 'clear_prediction.dart';
import 'clear_reward_effect.dart';
import 'piece_tray.dart';
import 'piece_view.dart';

class UnifiedGameScreen extends StatefulWidget {
  const UnifiedGameScreen.endless({this.audio, super.key}) : dailyChallenge = null;

  const UnifiedGameScreen.daily({
    required DailyChallengeDefinition challenge,
    this.audio,
    super.key,
  }) : dailyChallenge = challenge;

  final DailyChallengeDefinition? dailyChallenge;
  final GameAudioService? audio;

  bool get isDaily => dailyChallenge != null;

  @override
  State<UnifiedGameScreen> createState() => _UnifiedGameScreenState();
}

class _UnifiedGameScreenState extends State<UnifiedGameScreen> with WidgetsBindingObserver {
  final GlobalKey _boardGridKey = GlobalKey(debugLabel: 'blockiva-board-grid');
  late final GameSessionController _controller;
  late final GameAudioService _audio;
  final GameHaptics _haptics = GameHaptics();
  bool _feedbackReady = false;
  bool _active = true;
  bool _outcomeVisible = false;
  bool _newBest = false;
  bool _recordSoundPlayed = false;
  bool _recordFlash = false;
  int _startingBest = 0;
  int _outcomeToken = 0;
  int _trayGeneration = 0;

  _PlacementPreview? _preview;
  String? _moveFeedback;
  MoveResult? _clearReward;
  Offset? _rewardOrigin;
  Set<int> _clearedRows = <int>{};
  Set<int> _clearedCols = <int>{};
  var _feedbackToken = 0;
  var _rewardToken = 0;
  var _recordFlashToken = 0;
  var _clearFlashToken = 0;
  var _dailyFinished = false;
  var _dailySuccess = false;
  var _dailyRewardGranted = 0;

  DailyChallengeDefinition? get _daily => widget.dailyChallenge;

  bool get _terminal => widget.isDaily ? _dailyFinished : _controller.gameOver;

  int get _dailyMovesLeft {
    final DailyChallengeDefinition? daily = _daily;
    if (daily == null) return 0;
    return math.max(0, daily.moveLimit - _controller.engine.movesPlayed);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audio = widget.audio ?? GameAudioService();
    unawaited(_initializeAudio());

    final DailyChallengeDefinition? daily = _daily;
    if (daily == null) {
      _controller = GameSessionController(
        statsRepository: SharedPreferencesGameStatsRepository(),
        adService: kDebugMode
            ? const DebugRewardAdService()
            : const NoOpAdService(),
        progressionController: ProgressionRuntime.instance.controller,
      );
    } else {
      _controller = GameSessionController(
        statsRepository: _IsolatedDailyStatsRepository(),
        sessionRepository: SharedPreferencesGameSessionRepository(
          key: 'game.daily.${daily.dayKey}.v1',
        ),
        adService: const NoOpAdService(),
        pieceGenerator: DailyPieceGenerator(seed: daily.seed),
      );
    }

    _controller.addListener(_refresh);
    unawaited(_initializeController());
  }

  Future<void> _initializeController() async {
    await _controller.initialize();
    if (!mounted) return;
    _startingBest = _controller.bestScore;
    _evaluateDailyOutcome(playFeedback: false);
    _outcomeVisible = _terminal;
    setState(() {});
  }

  Future<void> _initializeAudio() async {
    await Future.wait([_audio.initialize(), _haptics.initialize()]);
    if (mounted) setState(() => _feedbackReady = true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _outcomeToken++;
    _controller
      ..removeListener(_refresh)
      ..dispose();
    unawaited(_audio.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _haptics.active = _active;
    unawaited(_audio.setActive(_active));
    if (!_active) unawaited(_controller.persistSession());
    setState(() {
      _preview = null;
      _trayGeneration++;
    });
  }

  Future<void> _showOutcome() async {
    final token = ++_outcomeToken;
    await Future<void>.delayed(const Duration(milliseconds: 460));
    if (!mounted || token != _outcomeToken || !_terminal) return;
    setState(() => _outcomeVisible = true);
    unawaited(_haptics.impact());
    unawaited(_dailySuccess ? _audio.playCombo()
        : _newBest ? _audio.playHighScore() : _audio.playGameOver());
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  RenderBox? get _boardBox {
    final BuildContext? context = _boardGridKey.currentContext;
    if (context == null) return null;
    final RenderObject? object = context.findRenderObject();
    return object is RenderBox && object.hasSize ? object : null;
  }

  double get _feedbackCellSize {
    final RenderBox? box = _boardBox;
    return box == null ? 38 : BoardDragProjector.feedbackCellSize(box.size);
  }

  void _updateDragPreview(BlockPiece piece, Offset globalPointer) {
    if (_terminal || !_active) return;
    final RenderBox? box = _boardBox;
    if (box == null) return;

    final BoardDropOrigin? origin = BoardDragProjector.project(
      pointerInBoard: box.globalToLocal(globalPointer),
      boardSize: box.size,
      piece: piece,
    );
    if (origin == null) {
      _setPreview(null);
      return;
    }

    _setPreview(
      _PlacementPreview(
        piece: piece,
        row: origin.row,
        col: origin.col,
        valid: _controller.engine.canPlace(piece, origin.row, origin.col),
      ),
    );
  }

  void _setPreview(_PlacementPreview? next) {
    if (!mounted || _preview == next) return;
    setState(() => _preview = next);
  }

  void _finishDrag(BlockPiece piece) {
    final _PlacementPreview? preview = _preview;
    if (!_terminal &&
        preview != null &&
        preview.piece.id == piece.id &&
        preview.valid) {
      _place(piece, preview.row, preview.col);
      return;
    }
    unawaited(_haptics.impact());
    unawaited(_audio.playInvalid());
    _setPreview(null);
  }

  void _place(BlockPiece piece, int row, int col) {
    if (_terminal || !_active) return;
    final bool placed = _controller.placePiece(piece, row, col);
    if (!placed) {
      unawaited(_haptics.impact());
      _setPreview(null);
      return;
    }

    final move = _controller.lastMove;
    if (move != null) {
      unawaited(_showMoveReward(
        move,
        Offset((col + piece.width / 2) / GameEngine.size,
            (row + piece.height / 2) / GameEngine.size),
      ));
    }
    if (move != null && move.linesCleared > 0) {
      unawaited(_haptics.reward());
      unawaited(_flashClearedLines(move.clearedRows, move.clearedCols));
      unawaited(move.combo > 1 ? _audio.playCombo() : _audio.playClear());
    } else {
      unawaited(_haptics.selection());
      unawaited(_audio.playPlacement());
    }

    _setPreview(null);
    _evaluateDailyOutcome();
    _newBest = !widget.isDaily && _controller.engine.score > _startingBest;
    if (_terminal) {
      unawaited(_showOutcome());
    } else if (_newBest && !_recordSoundPlayed) {
      _recordSoundPlayed = true;
      unawaited(_flashNewBest());
      if (move == null || move.linesCleared == 0) unawaited(_audio.playHighScore());
    }
  }

  void _evaluateDailyOutcome({bool playFeedback = true}) {
    final DailyChallengeDefinition? daily = _daily;
    if (daily == null || !_controller.initialized) return;

    final bool wasFinished = _dailyFinished;
    final bool alreadyCompleted = ProgressionRuntime.instance.controller
        .isDailyChallengeCompleted(daily.dayKey);
    final bool targetReached = _controller.engine.score >= daily.targetScore;
    final bool movesExhausted =
        _controller.engine.movesPlayed >= daily.moveLimit;
    final bool noMoves = _controller.gameOver;

    _dailySuccess = alreadyCompleted || targetReached;
    _dailyFinished = _dailySuccess || movesExhausted || noMoves;

    if (targetReached && !alreadyCompleted) {
      _dailyRewardGranted = ProgressionRuntime.instance.controller
          .completeDailyChallenge(
            dayKey: daily.dayKey,
            rewardCoins: daily.rewardCoins,
          );
    }

    if (!wasFinished && _dailyFinished && playFeedback) {
      if (_dailySuccess) {
        unawaited(_haptics.reward());
        unawaited(_audio.playCombo());
      } else {
        unawaited(_haptics.reward());
      }
    }
  }

  Future<void> _flashClearedLines(List<int> rows, List<int> cols) async {
    final int token = ++_clearFlashToken;
    if (mounted) {
      setState(() {
        _clearedRows = rows.toSet();
        _clearedCols = cols.toSet();
      });
    }
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted || token != _clearFlashToken) return;
    setState(() {
      _clearedRows = <int>{};
      _clearedCols = <int>{};
    });
  }

  Future<void> _showMoveReward(MoveResult move, Offset origin) async {
    final int token = ++_rewardToken;
    setState(() {
      _clearReward = move;
      _rewardOrigin = origin;
    });
    await Future<void>.delayed(Duration(milliseconds: move.linesCleared > 0 ? 680 : 540));
    if (!mounted || token != _rewardToken) return;
    setState(() {
      _clearReward = null;
      _rewardOrigin = null;
    });
  }

  Future<void> _flashNewBest() async {
    final int token = ++_recordFlashToken;
    setState(() => _recordFlash = true);
    await Future<void>.delayed(const Duration(milliseconds: 950));
    if (mounted && token == _recordFlashToken) {
      setState(() => _recordFlash = false);
    }
  }

  Future<void> _openSettings() async {
    unawaited(_audio.playButton());
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      backgroundColor: AppTheme.gameBoard,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, refresh) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('Settings', style: TextStyle(
                color: AppTheme.gameText, fontSize: 24, fontWeight: FontWeight.w800,
              )),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                title: const Text('Sound', style: TextStyle(color: AppTheme.gameText)),
                value: _audio.enabled,
                onChanged: (value) async {
                  await _audio.setEnabled(value);
                  if (!context.mounted) return;
                  refresh(() {});
                  if (value) unawaited(_audio.playButton());
                },
              ),
              SwitchListTile.adaptive(
                title: const Text('Haptics', style: TextStyle(color: AppTheme.gameText)),
                value: _haptics.enabled,
                onChanged: (value) async {
                  await _haptics.setEnabled(value);
                  if (!context.mounted) return;
                  refresh(() {});
                  if (value) unawaited(_haptics.selection());
                },
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: () => Navigator.pop(sheetContext),
                child: const Text('KEEP PLAYING')),
            ]),
          ),
        ),
      ),
    );
  }

  void _restart() {
    final DailyChallengeDefinition? daily = _daily;
    if (daily != null &&
        ProgressionRuntime.instance.controller.isDailyChallengeCompleted(
          daily.dayKey,
        )) {
      return;
    }

    setState(() {
      _preview = null;
      _moveFeedback = null;
      _clearReward = null;
      _rewardOrigin = null;
      _recordFlash = false;
      _clearedRows = <int>{};
      _clearedCols = <int>{};
      _outcomeVisible = false;
      _outcomeToken++;
      _trayGeneration++;
      _newBest = false;
      _recordSoundPlayed = false;
      _startingBest = _controller.bestScore;
      _dailyFinished = false;
      _dailySuccess = false;
      _dailyRewardGranted = 0;
      _feedbackToken += 1;
      _clearFlashToken += 1;
      _rewardToken += 1;
      _recordFlashToken += 1;
    });
    _controller.restart();
    unawaited(_haptics.selection());
    unawaited(_audio.playButton());
  }

  Future<void> _confirmRestart() async {
    if (_controller.engine.score == 0 && _controller.engine.movesPlayed == 0) {
      _restart();
      return;
    }

    unawaited(_audio.playButton());
    final bool? confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (BuildContext context) => _RestartSheet(
        daily: widget.isDaily,
        onCancel: () => Navigator.of(context).pop(false),
        onRestart: () => Navigator.of(context).pop(true),
      ),
    );
    if (confirmed == true && mounted) _restart();
  }

  Future<void> _revive() async {
    final bool revived = await _controller.rewardedRevive();
    if (!mounted || !revived) return;
    unawaited(_haptics.reward());
    unawaited(_audio.playCombo());
    setState(() {
      _preview = null;
      _moveFeedback = 'CONTINUE!';
      _outcomeVisible = false;
      _outcomeToken++;
    });
    final int token = ++_feedbackToken;
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (mounted && token == _feedbackToken) {
      setState(() => _moveFeedback = null);
    }
  }

  void _back() {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.initialized || !_feedbackReady) {
      return const BlockivaSplash();
    }

    Widget content = Scaffold(
      backgroundColor: AppTheme.gameBackgroundBottom,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              AppTheme.gameBackgroundTop,
              AppTheme.gameBackgroundBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                child: Column(
                  children: <Widget>[
                    _GameHeader(
                      daily: widget.isDaily,
                      onLeftAction: widget.isDaily ? _back : _openSettings,
                      onRestart: _confirmRestart,
                    ),
                    const SizedBox(height: 2),
                    if (widget.isDaily)
                      _ScoreDisplay(score: _controller.engine.score,
                        bestScore: _controller.bestScore, daily: _daily,
                        movesLeft: _dailyMovesLeft, lastMove: _controller.lastMove,
                        recordFlash: false)
                    else
                      ProgressionActions(score: _ScoreDisplay(
                        score: _controller.engine.score, bestScore: _controller.bestScore,
                        daily: null, movesLeft: 0,
                        lastMove: _controller.lastMove, recordFlash: _recordFlash,
                      )),
                    const SizedBox(height: 8),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (BuildContext context, BoxConstraints constraints) {
                          final double side = (constraints.maxHeight - 132)
                              .clamp(0.0, constraints.maxWidth).toDouble();
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              SizedBox(
                                width: side,
                                height: side,
                                child: RepaintBoundary(
                                  child: _Board(
                            gridKey: _boardGridKey,
                            engine: _controller.engine,
                            preview: _preview,
                            clearedRows: _clearedRows,
                            clearedCols: _clearedCols,
                            clearToken: _clearFlashToken,
                            reward: _clearReward,
                            rewardOrigin: _rewardOrigin,
                            rewardToken: _rewardToken,
                          ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              PieceTray(
                      key: ValueKey(_trayGeneration),
                      pieces: _controller.tray,
                      enabled: !_terminal && _active,
                      feedbackCellSize: () => _feedbackCellSize,
                      onDragStarted: () {
                        unawaited(_haptics.selection());
                        unawaited(_audio.playPickup());
                      },
                      onDragUpdate: _updateDragPreview,
                      onDragEnded: _finishDrag,
                      onDragCancelled: () => _setPreview(null),
                    ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: widget.isDaily ? 125 : 105,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (Widget child, Animation<double> animation) =>
                        FadeTransition(opacity: animation, child: ScaleTransition(
                          scale: Tween<double>(begin: .8, end: 1).animate(
                            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                          ), child: child,
                        )),
                    child: _moveFeedback == null
                        ? const SizedBox.shrink()
                        : Center(
                            key: ValueKey<String>(_moveFeedback!),
                            child: _MoveBurst(label: _moveFeedback!),
                          ),
                  ),
                ),
              ),
              if (!widget.isDaily && _outcomeVisible && _controller.gameOver)
                Positioned.fill(
                  child: _EndlessGameOverOverlay(
                    score: _controller.engine.score,
                    bestScore: _controller.bestScore,
                    coinsEarned: _controller.runCoinsAwarded,
                    newBest: _newBest,
                    canRevive: _controller.rewardedReviveReady,
                    onRestart: _restart,
                    onRevive: _revive,
                  ),
                ),
              if (widget.isDaily && _outcomeVisible && _dailyFinished)
                Positioned.fill(
                  child: _DailyOutcomeOverlay(
                    challenge: _daily!,
                    success: _dailySuccess,
                    score: _controller.engine.score,
                    rewardGranted: _dailyRewardGranted,
                    movesPlayed: _controller.engine.movesPlayed,
                    onRetry: _dailySuccess ? null : _restart,
                    onBack: _back,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (widget.isDaily) {
      final selected = ProgressionRuntime.instance.controller.selectedTheme;
      if (selected.id != 'classic') {
        content = ColorFiltered(
          colorFilter: ColorFilter.mode(
            Color(selected.backgroundTop),
            BlendMode.hue,
          ),
          child: content,
        );
      }
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.gameBackgroundBottom,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: content,
    );
  }
}

class _PlacementPreview {
  const _PlacementPreview({
    required this.piece,
    required this.row,
    required this.col,
    required this.valid,
  });

  final BlockPiece piece;
  final int row;
  final int col;
  final bool valid;

  bool contains(int row, int col) => piece.cells.any(
    (cell) => this.row + cell.row == row && this.col + cell.col == col,
  );

  @override
  bool operator ==(Object other) =>
      other is _PlacementPreview &&
      other.piece.id == piece.id &&
      other.row == row &&
      other.col == col &&
      other.valid == valid;

  @override
  int get hashCode => Object.hash(piece.id, row, col, valid);
}

class _GameHeader extends StatelessWidget {
  const _GameHeader({
    required this.daily,
    required this.onLeftAction,
    required this.onRestart,
  });

  final bool daily;
  final VoidCallback onLeftAction;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: <Widget>[
          _HudButton(
            icon: daily
                ? Icons.arrow_back_rounded
                : Icons.settings_rounded,
            tooltip: daily
                ? 'Back to endless'
                : 'Settings',
            onPressed: onLeftAction,
          ),
          Expanded(
            child: Text(
              daily ? 'DAILY CHALLENGE' : 'BLOCKIVA',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.gameText,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.7,
              ),
            ),
          ),
          _HudButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Restart',
            onPressed: onRestart,
          ),
        ],
      ),
    );
  }
}

class _HudButton extends StatelessWidget {
  const _HudButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: .10),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: AppTheme.gameText, size: 22),
          ),
        ),
      ),
    );
  }
}

class _ScoreDisplay extends StatelessWidget {
  const _ScoreDisplay({
    required this.score,
    required this.bestScore,
    required this.daily,
    required this.movesLeft,
    required this.lastMove,
    required this.recordFlash,
  });

  final int score;
  final int bestScore;
  final DailyChallengeDefinition? daily;
  final int movesLeft;
  final MoveResult? lastMove;
  final bool recordFlash;

  @override
  Widget build(BuildContext context) {
    final DailyChallengeDefinition? challenge = daily;
    return Column(
      children: <Widget>[
        SizedBox(
          height: 20,
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 220),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: .8, end: 1).animate(animation),
                child: child,
              ),
            ),
            child: Row(
              key: ValueKey<bool>(recordFlash),
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  challenge == null ? Icons.emoji_events_rounded : Icons.flag_rounded,
                  color: recordFlash ? AppTheme.rewardCoral : AppTheme.rewardGold,
                  size: 17,
                ),
                const SizedBox(width: 5),
                Text(
                  challenge != null ? 'TARGET ${challenge.targetScore}' :
                      recordFlash ? 'NEW BEST  $bestScore' : '$bestScore',
                  style: TextStyle(
                    color: recordFlash ? AppTheme.rewardGold : AppTheme.gameTextMuted,
                    fontSize: 14, fontWeight: FontWeight.w900,
                    letterSpacing: recordFlash ? .5 : 0,
                    shadows: recordFlash ? const <Shadow>[
                      Shadow(color: Color(0xAAEF6B88), blurRadius: 12),
                    ] : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 1),
        _AnimatedScore(
          score: score,
          accent: recordFlash ? AppTheme.rewardCoral :
              lastMove == null || lastMove!.linesCleared == 0
                  ? AppTheme.rewardCyan :
              lastMove!.combo > 1 ? AppTheme.rewardViolet :
              lastMove!.linesCleared > 1 ? AppTheme.rewardCoral : AppTheme.rewardGold,
        ),
        if (challenge != null) ...<Widget>[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$movesLeft MOVES LEFT  •  +${challenge.rewardCoins} COINS',
              style: const TextStyle(
                color: AppTheme.gameTextMuted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: .25,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Retargets from the current displayed value when moves arrive quickly.
class _AnimatedScore extends StatefulWidget {
  const _AnimatedScore({required this.score, required this.accent});

  final int score;
  final Color accent;

  @override
  State<_AnimatedScore> createState() => _AnimatedScoreState();
}

class _AnimatedScoreState extends State<_AnimatedScore> with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 420),
  );
  late double _from = widget.score.toDouble();
  late double _to = widget.score.toDouble();
  Color _activeAccent = AppTheme.rewardCyan;

  @override
  void didUpdateWidget(covariant _AnimatedScore oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score == widget.score) return;
    if (widget.score < oldWidget.score) {
      // Restart resets immediately instead of counting backward across an
      // empty board. Normal gains always continue from the visible number.
      _from = _to = widget.score.toDouble();
      _animation.value = 1;
      return;
    }
    _from = _currentValue;
    _to = widget.score.toDouble();
    _activeAccent = widget.accent;
    _animation.forward(from: 0);
  }

  double get _currentValue => _from + (_to - _from) * Curves.easeOutCubic.transform(_animation.value);

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animation,
    builder: (context, child) {
      final bool reducedMotion = MediaQuery.disableAnimationsOf(context);
      final double progress = reducedMotion ? 1 : _animation.value;
      final double value = reducedMotion ? _to : _currentValue;
      final Color color = Color.lerp(_activeAccent, AppTheme.gameText,
          reducedMotion ? 1 : Curves.easeOutCubic.transform(progress))!;
      return Transform.scale(
        scale: 1 + (reducedMotion ? 0 : .115 * math.sin(math.pi * progress)),
        child: Text(
          '${value.round()}',
          semanticsLabel: 'Score ${widget.score}',
          style: TextStyle(
            color: color,
            fontSize: 42,
            height: .95,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.5,
            shadows: <Shadow>[
              Shadow(color: _activeAccent.withValues(alpha: reducedMotion ? 0 :
                  .55 * (1 - progress)), blurRadius: 20),
              const Shadow(color: Color(0x55000000), blurRadius: 10, offset: Offset(0, 4)),
            ],
          ),
        ),
      );
    },
  );
}

class _Board extends StatelessWidget {
  const _Board({
    required this.gridKey,
    required this.engine,
    required this.preview,
    required this.clearedRows,
    required this.clearedCols,
    required this.clearToken,
    required this.reward,
    required this.rewardOrigin,
    required this.rewardToken,
  });

  final GlobalKey gridKey;
  final GameEngine engine;
  final _PlacementPreview? preview;
  final Set<int> clearedRows;
  final Set<int> clearedCols;
  final int clearToken;
  final MoveResult? reward;
  final Offset? rewardOrigin;
  final int rewardToken;

  @override
  Widget build(BuildContext context) {
    final placement = preview;
    final predicted = placement != null && placement.valid
        ? predictClears(engine, placement.piece, placement.row, placement.col)
        : (rows: <int>{}, cols: <int>{});
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppTheme.gameBoard,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x55030D22),
              blurRadius: 22,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: RepaintBoundary(
          key: gridKey,
          child: Stack(
          children: <Widget>[
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: GameEngine.size,
            ),
            itemCount: GameEngine.size * GameEngine.size,
            itemBuilder: (BuildContext context, int index) {
              final int row = index ~/ GameEngine.size;
              final int col = index % GameEngine.size;
              final int? paletteIndex = engine.cellAt(row, col);
              final bool previewed = preview?.contains(row, col) ?? false;
              final bool valid = previewed && (preview?.valid ?? false);
              final bool invalid = previewed && !(preview?.valid ?? true);
              return _BoardCell(
                paletteIndex: paletteIndex,
                previewPaletteIndex: valid ? preview!.piece.paletteIndex : null,
                invalidPreview: invalid,
                willClear: predicted.rows.contains(row) || predicted.cols.contains(col),
              );
            },
          ),
          if (clearedRows.isNotEmpty || clearedCols.isNotEmpty)
            Positioned.fill(child: BoardClearEffect(
              key: ValueKey<int>(clearToken), rows: clearedRows, cols: clearedCols,
            )),
          if (reward != null)
            Positioned.fill(child: ClearRewardEffect(
              key: ValueKey<int>(rewardToken),
              points: reward!.scoreGained,
              lines: reward!.linesCleared,
              combo: reward!.combo,
              rows: reward!.clearedRows.toSet(),
              cols: reward!.clearedCols.toSet(),
              placementCenter: rewardOrigin,
            )),
          ],
          ),
        ),
      ),
    );
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({
    required this.paletteIndex,
    required this.previewPaletteIndex,
    required this.invalidPreview,
    required this.willClear,
  });

  final int? paletteIndex;
  final int? previewPaletteIndex;
  final bool invalidPreview;
  final bool willClear;

  @override
  Widget build(BuildContext context) {
    final bool occupied = paletteIndex != null;
    final bool validPreview = previewPaletteIndex != null;
    final int? visualPalette = paletteIndex ?? previewPaletteIndex;
    return Opacity(
      opacity: validPreview && !occupied ? .48 : 1,
      child: visualPalette != null
          ? PuzzleTile(paletteIndex: visualPalette, highlighted: willClear)
          : AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              margin: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                color: invalidPreview ? const Color(0xFF6B3854) : AppTheme.gameCell,
                borderRadius: BorderRadius.circular(3),
                border: invalidPreview
                    ? Border.all(color: const Color(0xFFFF8B9B), width: 1.2)
                    : null,
              ),
            ),
    );
  }
}

class _MoveBurst extends StatelessWidget {
  const _MoveBurst({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.warning,
        fontSize: 20,
        fontWeight: FontWeight.w900,
        shadows: <Shadow>[
          Shadow(color: Color(0xAA07162F), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
    );
  }
}

class _RestartSheet extends StatelessWidget {
  const _RestartSheet({
    required this.daily,
    required this.onCancel,
    required this.onRestart,
  });

  final bool daily;
  final VoidCallback onCancel;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: AppTheme.gameBoard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: .10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            daily ? 'Restart today’s challenge?' : 'Restart this run?',
            style: const TextStyle(
              color: AppTheme.gameText,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            daily
                ? 'The same deterministic challenge will start from move 1.'
                : 'Your current board and score will be cleared.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.gameTextMuted),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: TextButton(
                  onPressed: onCancel,
                  child: const Text('KEEP PLAYING'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onRestart,
                  child: const Text('RESTART'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EndlessGameOverOverlay extends StatelessWidget {
  const _EndlessGameOverOverlay({
    required this.score,
    required this.bestScore,
    required this.coinsEarned,
    required this.newBest,
    required this.canRevive,
    required this.onRestart,
    required this.onRevive,
  });

  final int score;
  final int bestScore;
  final int coinsEarned;
  final bool newBest;
  final bool canRevive;
  final VoidCallback onRestart;
  final Future<void> Function() onRevive;

  @override
  Widget build(BuildContext context) {
    return _OverlayCard(
      icon: Icons.grid_off_rounded,
      title: newBest ? 'NEW PERSONAL BEST' : 'NO MORE MOVES',
      subtitle: coinsEarned > 0
          ? '+$coinsEarned coins earned this run'
          : 'Keep this run alive or start fresh.',
      score: score,
      secondary: 'BEST $bestScore',
      children: <Widget>[
        if (canRevive) ...<Widget>[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: const Color(0xFF062419),
                padding: const EdgeInsets.symmetric(vertical: 17),
              ),
              onPressed: onRevive,
              icon: const Icon(Icons.play_circle_fill_rounded),
              label: const Text('WATCH AD & CONTINUE'),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onRestart,
            icon: const Icon(Icons.replay_rounded),
            label: const Text('PLAY AGAIN'),
          ),
        ),
      ],
    );
  }
}

class _DailyOutcomeOverlay extends StatelessWidget {
  const _DailyOutcomeOverlay({
    required this.challenge,
    required this.success,
    required this.score,
    required this.rewardGranted,
    required this.movesPlayed,
    required this.onRetry,
    required this.onBack,
  });

  final DailyChallengeDefinition challenge;
  final bool success;
  final int score;
  final int rewardGranted;
  final int movesPlayed;
  final VoidCallback? onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _OverlayCard(
      icon: success ? Icons.workspace_premium_rounded : Icons.flag_rounded,
      title: success ? 'DAILY COMPLETE!' : 'CHALLENGE OVER',
      subtitle: success
          ? rewardGranted > 0
                ? '+$rewardGranted coins added'
                : 'Today’s reward is already secured.'
          : 'Target ${challenge.targetScore} • ${math.min(movesPlayed, challenge.moveLimit)}/${challenge.moveLimit} moves',
      score: score,
      secondary: success
          ? 'COME BACK TOMORROW'
          : '${math.max(0, challenge.targetScore - score)} MORE POINTS NEEDED',
      children: <Widget>[
        if (onRetry != null) ...<Widget>[
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('TRY AGAIN'),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('BACK TO ENDLESS'),
          ),
        ),
      ],
    );
  }
}

class _OverlayCard extends StatelessWidget {
  const _OverlayCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.score,
    required this.secondary,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final int score;
  final String secondary;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.gameOverlay,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 390),
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
            decoration: BoxDecoration(
              color: AppTheme.gameBoard,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withValues(alpha: .12)),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x88030D22),
                  blurRadius: 32,
                  offset: Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, color: AppTheme.warning, size: 42),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.gameText,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.gameTextMuted),
                ),
                const SizedBox(height: 18),
                Text(
                  '$score',
                  style: const TextStyle(
                    color: AppTheme.gameText,
                    fontSize: 46,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  secondary,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.gameTextMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 22),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IsolatedDailyStatsRepository implements GameStatsRepository {
  var _best = 0;
  var _games = 0;

  @override
  Future<int> loadBestScore() async => _best;

  @override
  Future<int> loadGamesPlayed() async => _games;

  @override
  Future<void> saveBestScore(int value) async => _best = value;

  @override
  Future<void> saveGamesPlayed(int value) async => _games = value;
}
