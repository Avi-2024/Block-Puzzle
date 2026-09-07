import 'package:flutter_test/flutter_test.dart';
import 'package:blockiva/core/ads/ad_service.dart';
import 'package:blockiva/core/storage/game_stats_repository.dart';
import 'package:blockiva/features/game/application/game_session_controller.dart';
import 'package:blockiva/features/game/domain/block_piece.dart';
import 'package:blockiva/features/game/domain/cell_offset.dart';
import 'package:blockiva/features/game/domain/game_engine.dart';
import 'package:blockiva/features/game/domain/piece_generator.dart';

class MemoryStatsRepository implements GameStatsRepository {
  MemoryStatsRepository({this.best = 0, this.games = 0});
  int best;
  int games;

  @override
  Future<int> loadBestScore() async => best;
  @override
  Future<int> loadGamesPlayed() async => games;
  @override
  Future<void> saveBestScore(int value) async { best = value; }
  @override
  Future<void> saveGamesPlayed(int value) async { games = value; }
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
  test('loads persisted stats and persists a new best score', () async {
    final MemoryStatsRepository repository = MemoryStatsRepository(best: 3, games: 9);
    final GameSessionController controller = GameSessionController(
      statsRepository: repository,
      adService: const NoOpAdService(),
      pieceGenerator: FixedSingleGenerator(),
    );
    await controller.initialize();
    expect(controller.bestScore, 3);
    expect(controller.gamesPlayed, 9);
    final BlockPiece first = controller.tray.first!;
    expect(controller.placePiece(first, 0, 0), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(controller.bestScore, 5);
    expect(repository.best, 5);
    controller.dispose();
  });
}
