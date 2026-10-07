import 'dart:math';

class Cell {
  const Cell(this.x, this.y);
  final int x;
  final int y;
}

const shapes = <List<Cell>>[
  [Cell(0, 0)],
  [Cell(0, 0), Cell(1, 0)],
  [Cell(0, 0), Cell(1, 0), Cell(2, 0)],
  [Cell(0, 0), Cell(1, 0), Cell(2, 0), Cell(3, 0)],
  [Cell(0, 0), Cell(1, 0), Cell(2, 0), Cell(3, 0), Cell(4, 0)],
  [Cell(0, 0), Cell(0, 1)],
  [Cell(0, 0), Cell(0, 1), Cell(0, 2)],
  [Cell(0, 0), Cell(0, 1), Cell(0, 2), Cell(0, 3)],
  [Cell(0, 0), Cell(1, 0), Cell(0, 1), Cell(1, 1)],
  [Cell(0, 0), Cell(1, 0), Cell(1, 1)],
  [Cell(0, 0), Cell(0, 1), Cell(1, 1)],
  [Cell(0, 0), Cell(1, 0), Cell(2, 0), Cell(1, 1)],
  [Cell(0, 0), Cell(1, 0), Cell(1, 1), Cell(2, 1)],
  [Cell(0, 0), Cell(0, 1), Cell(0, 2), Cell(1, 2)],
  [Cell(0, 0), Cell(1, 0), Cell(2, 0), Cell(0, 1), Cell(1, 1), Cell(2, 1)],
  [
    Cell(0, 0),
    Cell(1, 0),
    Cell(2, 0),
    Cell(0, 1),
    Cell(1, 1),
    Cell(2, 1),
    Cell(0, 2),
    Cell(1, 2),
    Cell(2, 2),
  ],
];

class Piece {
  const Piece(this.shape, this.color);
  final int shape;
  final int color;
  List<Cell> get cells => shapes[shape];
  int get width => cells.map((c) => c.x).reduce(max) + 1;
  int get height => cells.map((c) => c.y).reduce(max) + 1;
  Map<String, int> toJson() => {'shape': shape, 'color': color};
  static Piece? decode(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final shape = value['shape'], color = value['color'];
    if (shape is! int ||
        shape < 0 ||
        shape >= shapes.length ||
        color is! int ||
        color < 0 ||
        color > 4) {
      return null;
    }
    return Piece(shape, color);
  }
}

class PuzzleState {
  PuzzleState({
    required List<int> board,
    required List<Piece?> tray,
    this.score = 0,
    this.best = 0,
    this.combo = 0,
    this.moves = 0,
  }) : board = List.unmodifiable(board),
       tray = List.unmodifiable(tray);
  final List<int> board;
  final List<Piece?> tray;
  final int score;
  final int best;
  final int combo;
  final int moves;
  bool get gameOver =>
      !tray.whereType<Piece>().any((p) => canFitSomewhere(board, p));
  Map<String, Object?> toJson() => {
    'version': 1,
    'board': board,
    'tray': tray.map((p) => p?.toJson()).toList(),
    'score': score,
    'best': best,
    'combo': combo,
    'moves': moves,
  };
  static PuzzleState? decode(Object? value) {
    if (value is! Map<String, dynamic> || value['version'] != 1) return null;
    final board = value['board'], tray = value['tray'];
    if (board is! List ||
        board.length != 64 ||
        board.any((c) => c is! int || c < -1 || c > 4)) {
      return null;
    }
    if (tray is! List || tray.length != 3) return null;
    final pieces = <Piece?>[];
    for (final entry in tray) {
      final piece = Piece.decode(entry);
      if (entry != null && piece == null) return null;
      pieces.add(piece);
    }
    if (pieces.every((p) => p == null)) return null;
    for (final name in ['score', 'best', 'combo', 'moves']) {
      final number = value[name];
      if (number is! int || number < 0) return null;
    }
    return PuzzleState(
      board: board.cast<int>(),
      tray: pieces,
      score: value['score'] as int,
      best: max(value['score'] as int, value['best'] as int),
      combo: value['combo'] as int,
      moves: value['moves'] as int,
    );
  }
}

bool canPlace(List<int> board, Piece piece, int x, int y) {
  for (final cell in piece.cells) {
    final c = x + cell.x, r = y + cell.y;
    if (c < 0 || c >= 8 || r < 0 || r >= 8 || board[r * 8 + c] != -1) {
      return false;
    }
  }
  return true;
}

bool canFitSomewhere(List<int> board, Piece piece) {
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      if (canPlace(board, piece, x, y)) return true;
    }
  }
  return false;
}

class PuzzleMove {
  const PuzzleMove({
    required this.state,
    required this.beforeClear,
    required this.placed,
    required this.cleared,
    required this.rows,
    required this.columns,
    required this.points,
  });
  final PuzzleState state;
  final List<int> beforeClear;
  final Set<int> placed;
  final Set<int> cleared;
  final Set<int> rows;
  final Set<int> columns;
  final int points;
  int get lines => rows.length + columns.length;
  bool get allClear => state.board.every((c) => c == -1);
}

class PuzzleEngine {
  PuzzleEngine({Random? random}) : _random = random ?? Random();
  final Random _random;
  PuzzleState fresh({int best = 0}) {
    final board = List<int>.filled(64, -1);
    return PuzzleState(board: board, tray: _batch(board), best: best);
  }

  List<Piece?> _batch(List<int> board) {
    final result = List<Piece?>.generate(
      3,
      (_) => Piece(_random.nextInt(shapes.length), _random.nextInt(5)),
    );
    if (!result.whereType<Piece>().any((p) => canFitSomewhere(board, p))) {
      final fit = List<int>.generate(
        shapes.length,
        (i) => i,
      ).where((i) => canFitSomewhere(board, Piece(i, 0))).toList();
      if (fit.isNotEmpty) {
        result[0] = Piece(fit[_random.nextInt(fit.length)], _random.nextInt(5));
      }
    }
    return result;
  }

  PuzzleMove? place(PuzzleState current, int slot, int x, int y) {
    if (slot < 0 || slot >= 3) return null;
    final piece = current.tray[slot];
    if (piece == null || !canPlace(current.board, piece, x, y)) return null;
    final filled = List<int>.of(current.board), placed = <int>{};
    for (final c in piece.cells) {
      final index = (y + c.y) * 8 + x + c.x;
      filled[index] = piece.color;
      placed.add(index);
    }
    final rows = <int>{}, cols = <int>{};
    for (var i = 0; i < 8; i++) {
      if (List.generate(8, (j) => filled[i * 8 + j]).every((v) => v != -1)) {
        rows.add(i);
      }
      if (List.generate(8, (j) => filled[j * 8 + i]).every((v) => v != -1)) {
        cols.add(i);
      }
    }
    final cleared = <int>{
      for (final r in rows)
        for (var c = 0; c < 8; c++) r * 8 + c,
      for (final c in cols)
        for (var r = 0; r < 8; r++) r * 8 + c,
    };
    final board = List<int>.of(filled);
    for (final i in cleared) {
      board[i] = -1;
    }
    final combo = cleared.isEmpty ? 0 : current.combo + 1;
    final points =
        piece.cells.length * 10 + (rows.length + cols.length) * 80 * combo;
    var tray = List<Piece?>.of(current.tray)..[slot] = null;
    if (tray.every((p) => p == null)) tray = _batch(board);
    final state = PuzzleState(
      board: board,
      tray: tray,
      score: current.score + points,
      best: max(current.best, current.score + points),
      combo: combo,
      moves: current.moves + 1,
    );
    return PuzzleMove(
      state: state,
      beforeClear: List.unmodifiable(filled),
      placed: placed,
      cleared: cleared,
      rows: rows,
      columns: cols,
      points: points,
    );
  }
}

/// Original deterministic review scene: four consecutive moves produce 2,620.
PuzzleState reviewScene() => PuzzleState(
  board: [
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    -1,
    0,
    0,
    -1,
    -1,
    -1,
    4,
    4,
    4,
    1,
    1,
    4,
    4,
    0,
    0,
    -1,
    -1,
    1,
    1,
    3,
    3,
    0,
    0,
    3,
    -1,
    2,
    2,
    -1,
    -1,
    1,
    1,
    4,
    4,
    3,
    3,
    -1,
    -1,
    2,
    2,
    4,
    4,
    4,
    4,
    0,
    -1,
    -1,
    -1,
    -1,
    1,
  ],
  tray: const [Piece(2, 1), Piece(9, 2), Piece(8, 4)],
  score: 1280,
  best: 2460,
);
