import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/ads/ad_service.dart';
import '../../../core/storage/game_session_repository.dart';
import '../../../core/storage/game_stats_repository.dart';
import '../../../core/storage/shared_preferences_game_session_repository.dart';
import '../../progression/application/progression_controller.dart';
import '../../progression/application/progression_runtime.dart';
import '../domain/block_piece.dart';
import '../domain/game_engine.dart';
import '../domain/game_session_state.dart';
import '../domain/game_snapshot.dart';
import '../domain/move_result.dart';
import '../domain/piece_generator.dart';

class GameSessionController extends ChangeNotifier {
  GameSessionController({
    required GameStatsRepository statsRepository,
    GameSessionRepository? sessionRepository,
    required AdService adService,
    ProgressionController? progressionController,
    GameEngine? engine,
    PieceGenerator? pieceGenerator,
  })  : _statsRepository = statsRepository,
        _sessionRepository =
            sessionRepository ?? SharedPreferencesGameSessionRepository(),
        _adService = adService,
        _progressionController = progressionController ??
            ProgressionRuntime.instance.controller,
        engine = engine ?? GameEngine(),
        _pieceGenerator = pieceGenerator ?? PieceGenerator();

  static const int maxRevivesPerGame = 1;

  final GameStatsRepository _statsRepository;
  final GameSessionRepository _sessionRepository;
  final AdService _adService;
  final ProgressionController _progressionController;
  final PieceGenerator _pieceGenerator;
  final GameEngine engine;

  List<BlockPiece?> tray = <BlockPiece?>[];
  MoveResult? lastMove;
  GameSnapshot? _gameOverSnapshot;

  var bestScore = 0;
  var gamesPlayed = 0;
  var gameOver = false;
  var revivesUsed = 0;
  var runEndRecorded = false;
  var runCoinsAwarded = 0;
  var initialized = false;

  bool get rewardedReviveReady =>
      gameOver &&
      revivesUsed < maxRevivesPerGame &&
      _adService.rewardedReady &&
      tray.whereType<BlockPiece>().isNotEmpty;

  Future<void> initialize() async {
    if (initialized) return;

    final Future<int> bestFuture = _statsRepository.loadBestScore();
    final Future<int> gamesFuture = _statsRepository.loadGamesPlayed();
    final Future<GameSessionState?> sessionFuture = _sessionRepository.load();

    bestScore = await bestFuture;
    gamesPlayed = await gamesFuture;
    final GameSessionState? savedSession = await sessionFuture;

    final bool restored = savedSession != null && _restoreSession(savedSession);
    if (!restored) {
      engine.reset();
      tray = _newTray();
      gameOver = false;
      revivesUsed = 0;
      runEndRecorded = false;
      runCoinsAwarded = 0;
      _gameOverSnapshot = null;
      if (savedSession != null) {
        await _sessionRepository.clear();
      }
    }

    initialized = true;
    await persistSession();
    notifyListeners();
  }

  bool placePiece(BlockPiece piece, int row, int col) {
    if (!initialized || gameOver) return false;
    final MoveResult result = engine.place(piece, row, col);
    if (!result.accepted) return false;

    lastMove = result;
    final int trayIndex = tray.indexWhere(
      (BlockPiece? candidate) => candidate?.id == piece.id,
    );
    if (trayIndex >= 0) tray[trayIndex] = null;

    if (tray.every((BlockPiece? piece) => piece == null)) {
      tray = _newTray();
    }

    if (engine.score > bestScore) {
      bestScore = engine.score;
      unawaited(_statsRepository.saveBestScore(bestScore));
    }

    _progressionController.recordMove(
      linesCleared: result.linesCleared,
      combo: result.combo,
      currentScore: engine.score,
      bestScore: bestScore,
      gamesPlayed: gamesPlayed,
    );

    _recomputeGameOver();
    unawaited(persistSession());
    notifyListeners();
    return true;
  }

  void restart() {
    engine.reset();
    tray = _newTray();
    lastMove = null;
    _gameOverSnapshot = null;
    gameOver = false;
    revivesUsed = 0;
    runEndRecorded = false;
    runCoinsAwarded = 0;
    unawaited(persistSession());
    notifyListeners();
  }

  Future<bool> rewardedRevive() async {
    if (!rewardedReviveReady) return false;
    final bool rewardGranted =
        await _adService.showRewarded(RewardPlacement.revive);
    if (!rewardGranted) return false;

    final GameSnapshot? snapshot = _gameOverSnapshot;
    if (snapshot == null) return false;
    engine.restore(snapshot);

    final bool recovered = engine.reviveFor(tray.whereType<BlockPiece>());
    if (!recovered) return false;

    revivesUsed += 1;
    gameOver = false;
    _gameOverSnapshot = null;
    await persistSession();
    notifyListeners();
    return true;
  }

  Future<void> persistSession() async {
    if (!initialized) return;
    await _sessionRepository.save(
      GameSessionState(
        snapshot: engine.snapshot(),
        tray: List<BlockPiece?>.from(tray),
        gameOver: gameOver,
        revivesUsed: revivesUsed,
        runEndRecorded: runEndRecorded,
        runCoinsAwarded: runCoinsAwarded,
      ),
    );
  }

  bool _restoreSession(GameSessionState state) {
    if (state.revivesUsed > maxRevivesPerGame) return false;
    if (state.tray.length != 3 ||
        state.tray.every((BlockPiece? piece) => piece == null)) {
      return false;
    }

    try {
      engine.restore(state.snapshot);
    } on ArgumentError {
      return false;
    }

    tray = List<BlockPiece?>.from(state.tray);
    revivesUsed = state.revivesUsed;
    runEndRecorded = state.runEndRecorded;
    runCoinsAwarded = state.runCoinsAwarded;

    final List<BlockPiece> remaining = tray.whereType<BlockPiece>().toList();
    final bool computedGameOver =
        remaining.isNotEmpty && !engine.anyPieceCanBePlaced(remaining);
    if (computedGameOver != state.gameOver) {
      engine.reset();
      return false;
    }

    gameOver = state.gameOver;
    _gameOverSnapshot = gameOver ? engine.snapshot() : null;
    return true;
  }

  List<BlockPiece?> _newTray() =>
      List<BlockPiece?>.from(_pieceGenerator.nextTray(engine));

  void _recomputeGameOver() {
    final List<BlockPiece> remaining = tray.whereType<BlockPiece>().toList();
    final bool nextGameOver =
        remaining.isNotEmpty && !engine.anyPieceCanBePlaced(remaining);

    if (!gameOver && nextGameOver) {
      _gameOverSnapshot = engine.snapshot();

      if (!runEndRecorded) {
        runEndRecorded = true;
        gamesPlayed += 1;
        unawaited(_statsRepository.saveGamesPlayed(gamesPlayed));
        runCoinsAwarded = _progressionController.recordRunCompleted(
          score: engine.score,
          linesCleared: engine.totalLinesCleared,
          bestScore: bestScore,
          gamesPlayed: gamesPlayed,
        );
      }
    }
    gameOver = nextGameOver;
  }
}
