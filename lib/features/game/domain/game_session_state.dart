import 'block_piece.dart';
import 'cell_offset.dart';
import 'game_snapshot.dart';

class GameSessionState {
  const GameSessionState({
    required this.snapshot,
    required this.tray,
    required this.gameOver,
    required this.revivesUsed,
  });

  static const int schemaVersion = 1;

  final GameSnapshot snapshot;
  final List<BlockPiece?> tray;
  final bool gameOver;
  final int revivesUsed;

  Map<String, Object?> toJson() => <String, Object?>{
        'version': schemaVersion,
        'board': snapshot.board,
        'score': snapshot.score,
        'combo': snapshot.combo,
        'totalLinesCleared': snapshot.totalLinesCleared,
        'movesPlayed': snapshot.movesPlayed,
        'tray': tray.map(_pieceToJson).toList(growable: false),
        'gameOver': gameOver,
        'revivesUsed': revivesUsed,
      };

  static GameSessionState? fromJson(Map<String, Object?> json) {
    if (json['version'] != schemaVersion) return null;

    try {
      final Object? rawBoard = json['board'];
      final Object? rawTray = json['tray'];
      if (rawBoard is! List<Object?> || rawTray is! List<Object?>) return null;
      if (rawBoard.length != 8 || rawTray.length != 3) return null;

      final List<List<int?>> board = rawBoard.map((Object? rawRow) {
        if (rawRow is! List<Object?> || rawRow.length != 8) {
          throw const FormatException('Invalid board row.');
        }
        return rawRow.map((Object? value) {
          if (value == null) return null;
          if (value is! int || value < 0 || value > 5) {
            throw const FormatException('Invalid board cell.');
          }
          return value;
        }).toList(growable: false);
      }).toList(growable: false);

      final List<BlockPiece?> tray = rawTray
          .map((Object? value) => value == null ? null : _pieceFromJson(value))
          .toList(growable: false);

      final int score = _nonNegativeInt(json['score']);
      final int combo = _nonNegativeInt(json['combo']);
      final int totalLinesCleared = _nonNegativeInt(json['totalLinesCleared']);
      final int movesPlayed = _nonNegativeInt(json['movesPlayed']);
      final int revivesUsed = _nonNegativeInt(json['revivesUsed']);
      final Object? gameOverValue = json['gameOver'];
      if (gameOverValue is! bool) return null;

      return GameSessionState(
        snapshot: GameSnapshot(
          board: board,
          score: score,
          combo: combo,
          totalLinesCleared: totalLinesCleared,
          movesPlayed: movesPlayed,
        ),
        tray: tray,
        gameOver: gameOverValue,
        revivesUsed: revivesUsed,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  static Object? _pieceToJson(BlockPiece? piece) {
    if (piece == null) return null;
    return <String, Object?>{
      'id': piece.id,
      'shapeId': piece.shapeId,
      'paletteIndex': piece.paletteIndex,
      'cells': piece.cells
          .map((CellOffset cell) => <int>[cell.row, cell.col])
          .toList(growable: false),
    };
  }

  static BlockPiece _pieceFromJson(Object? raw) {
    if (raw is! Map<String, Object?>) {
      throw const FormatException('Invalid piece.');
    }
    final Object? id = raw['id'];
    final Object? shapeId = raw['shapeId'];
    final Object? paletteIndex = raw['paletteIndex'];
    final Object? rawCells = raw['cells'];
    if (id is! String || id.isEmpty || shapeId is! String || shapeId.isEmpty) {
      throw const FormatException('Invalid piece identity.');
    }
    if (paletteIndex is! int || paletteIndex < 0 || paletteIndex > 5) {
      throw const FormatException('Invalid piece palette.');
    }
    if (rawCells is! List<Object?> || rawCells.isEmpty) {
      throw const FormatException('Invalid piece cells.');
    }

    final List<CellOffset> cells = rawCells.map((Object? rawCell) {
      if (rawCell is! List<Object?> || rawCell.length != 2) {
        throw const FormatException('Invalid piece cell.');
      }
      final Object? row = rawCell[0];
      final Object? col = rawCell[1];
      if (row is! int || col is! int || row < 0 || col < 0 || row > 7 || col > 7) {
        throw const FormatException('Invalid piece coordinate.');
      }
      return CellOffset(row, col);
    }).toList(growable: false);

    return BlockPiece(
      id: id,
      shapeId: shapeId,
      cells: cells,
      paletteIndex: paletteIndex,
    );
  }

  static int _nonNegativeInt(Object? value) {
    if (value is! int || value < 0) {
      throw const FormatException('Expected non-negative integer.');
    }
    return value;
  }
}
