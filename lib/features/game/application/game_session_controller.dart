import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/ads/ad_service.dart';
import '../../../core/storage/game_stats_repository.dart';
import '../domain/block_piece.dart';
import '../domain/game_engine.dart';
import '../domain/game_snapshot.dart';
import '../domain/move_result.dart';
import '../domain/piece_generator.dart';

class GameSessionController extends ChangeNotifier {
  GameSessionController({
    required GameStatsRepository statsRepository,
    required AdService adService,
    GameEngine? engine,
    PieceGenerator? pieceGenerator,
  })  : _statsRepository = statsRepository,
        _adService = adService,
        engine = engine ?? GameEngine(),
        _pieceGenerator = pieceGenerator ?? PieceGenerator();

  static const int maxRevivesPerGame = 1;

  final GameStatsRepository _statsRepository;
  final AdService _adService;
  final PieceGenerator _pieceGenerator;
  final GameEngine engine;

  List<BlockPiece?> tray = <BlockPiece?>[];
  MoveResult? lastMove;
  GameSnapshot? _gameOverSnapshot;

  var bestScore = 0;
  var gamesPlayed = 0;
  var gameOver = false;
  var revivesUsed = 0;
  var initialized = false;

  bool get rewardedReviveReady =>
      gameOver &&
      revivesUsed < maxRevivesPerGame &&
      _adService.rewardedReady &&
      tray.whereType<BlockPiece>().isNotEmpty;

  Future<void> initialize() async {
    if (initialized) return;
    final List<int> values = await Future.wait(<Future<int>>[
      _statsRepository.loadBestScore(),
      _statsRepository.loadGamesPlayed(),
    ]);
    bestScore = values[0];
    gamesPlayed = values[1];
    tray = _newTray();
    initialized = true;
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

    _recomputeGameOver();
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
    notifyListeners();
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
      gamesPlayed += 1;
      unawaited(_statsRepository.saveGamesPlayed(gamesPlayed));
    }
    gameOver = nextGameOver;
  }
}
