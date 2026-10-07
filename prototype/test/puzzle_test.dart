import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_prototype/game/puzzle.dart';
import 'package:puzzle_prototype/game/puzzle_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('invalid and consumed placements cannot alter a session', () {
    final engine = PuzzleEngine(random: Random(4)), state = reviewScene();
    expect(engine.place(state, 0, 0, 2), isNull);
    expect(engine.place(state, 0, 7, 0), isNull);
    expect(state.score, 1280);
    expect(state.board[18], -1);
    final move = engine.place(state, 0, 2, 2)!;
    expect(engine.place(move.state, 0, 0, 0), isNull);
  });
  test(
    'intersecting row and column clear together without double-counting the cell',
    () {
      final board = List<int>.filled(64, -1);
      for (var i = 0; i < 8; i++) {
        board[3 * 8 + i] = 0;
        board[i * 8 + 4] = 1;
      }
      board[28] = -1;
      final state = PuzzleState(
        board: board,
        tray: const [Piece(0, 2), Piece(8, 3), Piece(2, 4)],
      );
      final move = PuzzleEngine().place(state, 0, 4, 3)!;
      expect(move.rows, {3});
      expect(move.columns, {4});
      expect(move.cleared.length, 15);
      expect(move.state.board.every((c) => c == -1), isTrue);
      expect(move.points, 170);
    },
  );
  test(
    'consecutive clears multiply bonuses; an ordinary placement resets the streak',
    () {
      final engine = PuzzleEngine(random: Random(3));
      final first = engine.place(reviewScene(), 0, 2, 2)!;
      expect(first.points, 110);
      expect(first.state.combo, 1);
      final second = engine.place(first.state, 1, 6, 3)!;
      expect(second.points, 350);
      expect(second.state.combo, 2);
      final ordinary = engine.place(second.state, 2, 0, 0)!;
      expect(ordinary.points, 40);
      expect(ordinary.state.combo, 0);
      expect(ordinary.state.tray.whereType<Piece>().length, 3);
    },
  );
  test(
    'review progression earns the visible 2620 and clears the entire board',
    () {
      final engine = PuzzleEngine(random: Random(5));
      var state = reviewScene();
      for (final input in [(0, 2, 2), (1, 6, 3), (2, 2, 5)]) {
        state = engine.place(state, input.$1, input.$2, input.$3)!.state;
      }
      expect(state.score, 2260);
      state = PuzzleState(
        board: state.board,
        tray: const [Piece(3, 3), Piece(10, 1), Piece(6, 0)],
        score: state.score,
        best: state.best,
        combo: state.combo,
        moves: state.moves,
      );
      final last = engine.place(state, 0, 3, 7)!;
      expect(last.state.score, 2620);
      expect(last.state.best, 2620);
      expect(last.state.combo, 4);
      expect(last.allClear, isTrue);
    },
  );
  test('game over checks every remaining shape and every position', () {
    final board = List<int>.filled(64, 0)..[63] = -1;
    expect(
      PuzzleState(board: board, tray: const [Piece(2, 1), null, null]).gameOver,
      isTrue,
    );
    expect(
      PuzzleState(
        board: board,
        tray: const [Piece(2, 1), Piece(0, 3), null],
      ).gameOver,
      isFalse,
    );
  });
  test(
    'saved sessions round trip; malformed shapes and cell values are rejected',
    () {
      final state = reviewScene();
      final decoded = PuzzleState.decode(
        jsonDecode(jsonEncode(state.toJson())),
      )!;
      expect(decoded.board, state.board);
      expect(decoded.tray[1]!.shape, 9);
      expect(decoded.best, 2460);
      final corrupt = state.toJson()
        ..['tray'] = [
          {'shape': 999, 'color': 0},
          null,
          null,
        ];
      expect(PuzzleState.decode(corrupt), isNull);
      expect(
        PuzzleState.decode(state.toJson()..['board'] = List.filled(64, 8)),
        isNull,
      );
    },
  );
  test(
    'queued saves preserve the latest move and restore best independently',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = PuzzleStore(await SharedPreferences.getInstance()),
          engine = PuzzleEngine();
      final first = engine.place(reviewScene(), 0, 2, 2)!.state;
      final second = engine.place(first, 1, 6, 3)!.state;
      await Future.wait([store.save(first), store.save(second)]);
      expect(store.load(engine).score, 1740);
      await store.preferences.setString(PuzzleStore.sessionKey, 'invalid json');
      expect(store.load(engine).score, 0);
      expect(store.load(engine).best, 2460);
    },
  );
}
