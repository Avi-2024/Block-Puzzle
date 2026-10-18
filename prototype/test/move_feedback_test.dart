import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_prototype/game/feedback_review.dart';
import 'package:puzzle_prototype/game/move_feedback.dart';
import 'package:puzzle_prototype/game/puzzle.dart';

void main() {
  for (final scene in feedbackReviews) {
    test('${scene.reward.name}: hover and drop recolour only the completed lines', () {
      final state = scene.state;
      final saved = state.toJson();
      final hover = ClearFeedback.preview(state.board, scene.piece, scene.x, scene.y);
      final engine = PuzzleEngine(random: Random(8));
      final move = engine.place(state, 0, scene.x, scene.y)!;
      final dropped = ClearFeedback.forMove(move);
      expect(rewardForMove(move), scene.reward);
      expect(hover.rows, scene.rows);
      expect(hover.columns, scene.columns);
      expect(hover.cells, move.cleared);
      expect(dropped.cells, hover.cells);
      for (var i = 0; i < 64; i++) {
        if (move.cleared.contains(i)) {
          expect(hover.colorAt(i, state.board[i]), scene.piece.color);
          expect(dropped.colorAt(i, move.beforeClear[i]), scene.piece.color);
          expect(move.state.board[i], -1);
        } else {
          expect(hover.colorAt(i, state.board[i]), state.board[i]);
          expect(dropped.colorAt(i, move.beforeClear[i]), move.beforeClear[i]);
        }
      }
      expect(state.toJson(), saved); // Rendering never mutates the saved game.
      expect(move.beforeClear[0], 4); // Unrelated colour remains untouched.
      expect(move.state.board[0], 4);
      expect(move.state.score, state.score + move.points);
      final replay = PuzzleEngine(random: Random(8)).place(state, 0, scene.x, scene.y)!;
      expect(move.state.toJson(), replay.state.toJson()); // Preview consumes no RNG.
    });
  }

  test('moving off a clear, invalid placement and cancellation leave no tint', () {
    final scene = feedbackReviews.first, board = feedbackReviews.first.state.board;
    expect(ClearFeedback.preview(board, scene.piece, scene.x, scene.y).isEmpty, isFalse);
    for (final position in [(0, 1), (0, 0), (-1, 0), (7, 4)]) {
      final feedback = ClearFeedback.preview(board, scene.piece, position.$1, position.$2);
      expect(feedback.isEmpty, isTrue);
      for (var i = 0; i < 64; i++) {
        expect(feedback.colorAt(i, board[i]), board[i]);
      }
    }
    expect(const ClearFeedback().colorAt(32, board[32]), board[32]);
  });

  test('a crossing clear colours the shared cell once and counts both lines', () {
    final scene = feedbackReviews[3];
    final move = PuzzleEngine().place(scene.state, 0, scene.x, scene.y)!;
    expect(move.lines, 2);
    expect(ClearFeedback.forMove(move).cells.length, 15);
    expect(move.state.linesCleared, 2);
  });

  test('a record can happen without a clear and is announced only on crossing', () {
    final engine = PuzzleEngine();
    final state = PuzzleState(board: List.filled(64, -1),
      tray: const [Piece(0, 2), Piece(0, 4), Piece(0, 1)],
      score: 100, best: 105, startingBest: 105);
    final first = engine.place(state, 0, 0, 0)!;
    expect(first.lines, 0);
    expect(rewardForMove(first), RewardKind.newBest);
    expect(ClearFeedback.forMove(first).isEmpty, isTrue);
    final second = engine.place(first.state, 1, 1, 0)!;
    expect(rewardForMove(second), isNull);
  });
}
