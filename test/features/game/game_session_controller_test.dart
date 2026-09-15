import 'package:blockiva/core/ads/ad_service.dart';
import 'package:blockiva/core/storage/game_session_repository.dart';
import 'package:blockiva/core/storage/game_stats_repository.dart';
import 'package:blockiva/features/game/application/game_session_controller.dart';
import 'package:blockiva/features/game/domain/block_piece.dart';
import 'package:blockiva/features/game/domain/cell_offset.dart';
import 'package:blockiva/features/game/domain/game_engine.dart';
import 'package:blockiva/features/game/domain/game_session_state.dart';
import 'package:blockiva/features/game/domain/piece_generator.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryStatsRepository implements GameStatsRepository {
  MemoryStatsRepository({this.best = 0, this.games = 0});

  int best;
  int games;

  @override
  Future<int> loadBestScore() async => best;

  @override
  Future<int> loadGamesPlayed() async => games;

  @override
  Future<void> saveBestScore(int value) async {
    best = value;
  }

  @override
  Future<void> saveGamesPlayed(int value) async {
    games = value;
  }
}

class MemorySessionRepository implements GameSessionRepository {
  GameSessionState? state;

  @override
  Future<void> clear() async {
    state = null;
  }

  @override
  Future<GameSessionState?> load() async => state;

  @override
  Future<void> save(GameSessionState value) async {
    state = value;
  }
}

class FixedSingleGenerator extends PieceGenerator {
  var sequence = 0;

  @override
  List<BlockPiece> nextTray(GameEngine engine) {
    return List<BlockPiece>.generate(3, (int index) {
      sequence += 1;
      return BlockPiece(
        id: 'single-$sequence',
        shapeId: 'single',
        cells: const <CellOffset>[CellOffset(0, 0)],
        paletteIndex: index,
      );
    });
  }
}

void main() {
  test('a consumed piece cannot add blocks or score a second time', () async {
    final MemorySessionRepository sessions = MemorySessionRepository();
    final GameSessionController controller = GameSessionController(
      statsRepository: MemoryStatsRepository(),
      sessionRepository: sessions,
      adService: const NoOpAdService(),
      pieceGenerator: FixedSingleGenerator(),
    );
    await controller.initialize();
    final BlockPiece piece = controller.tray.first!;
    expect(controller.placePiece(piece, 0, 0), isTrue);
    final before = sessions.state!.toJson();
    var notifications = 0;
    controller.addListener(() => notifications++);

    expect(controller.placePiece(piece, 0, 1), isFalse);
    expect(controller.engine.cellAt(0, 1), isNull);
    expect(controller.engine.score, 5);
    expect(controller.engine.movesPlayed, 1);
    expect(controller.tray.whereType<BlockPiece>(), hasLength(2));
    expect(sessions.state!.toJson(), before);
    expect(notifications, 0);
    controller.dispose();
  });

  test(
    'a foreign piece with a matching ID cannot consume a live slot',
    () async {
      final GameSessionController controller = GameSessionController(
        statsRepository: MemoryStatsRepository(),
        sessionRepository: MemorySessionRepository(),
        adService: const NoOpAdService(),
        pieceGenerator: FixedSingleGenerator(),
      );
      await controller.initialize();
      final BlockPiece live = controller.tray.first!;
      final BlockPiece foreign = BlockPiece(
        id: live.id,
        shapeId: 'h2',
        cells: const <CellOffset>[CellOffset(0, 0), CellOffset(0, 1)],
        paletteIndex: 4,
      );
      expect(controller.placePiece(foreign, 0, 0), isFalse);
      expect(controller.engine.score, 0);
      expect(controller.engine.cellAt(0, 0), isNull);
      expect(controller.tray.first, same(live));

      controller.restart();
      expect(controller.placePiece(live, 0, 0), isFalse);
      expect(controller.engine.movesPlayed, 0);
      controller.dispose();
    },
  );

  test('refills only after three live pieces are consumed', () async {
    final GameSessionController controller = GameSessionController(
      statsRepository: MemoryStatsRepository(),
      sessionRepository: MemorySessionRepository(),
      adService: const NoOpAdService(),
      pieceGenerator: FixedSingleGenerator(),
    );
    await controller.initialize();
    final original = controller.tray.whereType<BlockPiece>().toList();
    expect(controller.placePiece(original[2], 0, 0), isTrue);
    expect(controller.tray[0], same(original[0]));
    expect(controller.placePiece(original[0], 0, 0), isFalse);
    expect(controller.tray[0], same(original[0]));
    expect(controller.placePiece(original[0], 1, 0), isTrue);
    expect(controller.placePiece(original[1], 2, 0), isTrue);
    expect(controller.tray.whereType<BlockPiece>(), hasLength(3));
    expect(controller.tray.any(original.contains), isFalse);
    expect(controller.gameOver, isFalse);
    controller.dispose();
  });

  test('loads stats and persists best score plus active session', () async {
    final MemoryStatsRepository stats = MemoryStatsRepository(
      best: 3,
      games: 9,
    );
    final MemorySessionRepository sessions = MemorySessionRepository();
    final GameSessionController controller = GameSessionController(
      statsRepository: stats,
      sessionRepository: sessions,
      adService: const NoOpAdService(),
      pieceGenerator: FixedSingleGenerator(),
    );

    await controller.initialize();
    expect(controller.bestScore, 3);
    expect(controller.gamesPlayed, 9);

    final BlockPiece first = controller.tray.first!;
    expect(controller.placePiece(first, 0, 0), isTrue);
    await controller.persistSession();
    await Future<void>.delayed(Duration.zero);

    expect(controller.bestScore, 5);
    expect(stats.best, 5);
    expect(sessions.state, isNotNull);
    expect(sessions.state!.snapshot.board[0][0], isNotNull);
    expect(sessions.state!.tray.first, isNull);
    controller.dispose();
  });

  test(
    'restores board, tray and revive usage from a valid saved session',
    () async {
      final MemoryStatsRepository stats = MemoryStatsRepository(best: 500);
      final MemorySessionRepository sessions = MemorySessionRepository();
      final FixedSingleGenerator generator = FixedSingleGenerator();

      final GameSessionController first = GameSessionController(
        statsRepository: stats,
        sessionRepository: sessions,
        adService: const NoOpAdService(),
        pieceGenerator: generator,
      );
      await first.initialize();
      final BlockPiece piece = first.tray.first!;
      expect(first.placePiece(piece, 2, 3), isTrue);
      await first.persistSession();
      final String remainingId = first.tray.whereType<BlockPiece>().first.id;
      first.dispose();

      final GameSessionController restored = GameSessionController(
        statsRepository: stats,
        sessionRepository: sessions,
        adService: const NoOpAdService(),
        pieceGenerator: FixedSingleGenerator(),
      );
      await restored.initialize();

      expect(restored.engine.cellAt(2, 3), isNotNull);
      expect(restored.tray.whereType<BlockPiece>().first.id, remainingId);
      expect(restored.engine.score, 5);
      expect(restored.gameOver, isFalse);
      restored.dispose();
    },
  );
}
