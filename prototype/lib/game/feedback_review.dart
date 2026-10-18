import 'move_feedback.dart';
import 'puzzle.dart';

/// Deterministic moves for the separate Android review build and visual tests.
/// The ordinary app continues to start from the player's saved session.
class FeedbackReview {
  const FeedbackReview(
    this.reward,
    this.piece,
    this.x,
    this.y,
    this.rows,
    this.columns,
    this.combo,
  );
  final RewardKind reward;
  final Piece piece;
  final int x, y, combo;
  final Set<int> rows, columns;

  PuzzleState get state {
    final board = List<int>.filled(64, -1);
    final gaps = {for (final c in piece.cells) (y + c.y) * 8 + x + c.x};
    for (var i = 0; i < 64; i++) {
      if ((rows.contains(i ~/ 8) || columns.contains(i % 8)) &&
          !gaps.contains(i)) {
        board[i] = (i * 3 + i ~/ 8) % puzzleColorCount;
      }
    }
    board[0] = 4; // Keep an unrelated block to check its colour never changes.
    final best = reward == RewardKind.newBest ? 1050 : 5000;
    return PuzzleState(
      board: board,
      tray: [piece, const Piece(8, 0), const Piece(2, 4)],
      score: 1000,
      best: best,
      startingBest: best,
      combo: combo,
      maxCombo: combo,
    );
  }
}

const feedbackReviews = [
  FeedbackReview(RewardKind.good, Piece(1, 1), 3, 4, {4}, {}, 0),
  FeedbackReview(RewardKind.great, Piece(8, 4), 3, 4, {4, 5}, {}, 0),
  FeedbackReview(RewardKind.combo, Piece(5, 6), 3, 3, {}, {3}, 1),
  FeedbackReview(RewardKind.amazing, Piece(0, 5), 3, 3, {3}, {3}, 2),
  FeedbackReview(RewardKind.incredible, Piece(15, 2), 2, 3, {3, 4, 5}, {}, 3),
  FeedbackReview(RewardKind.newBest, Piece(2, 3), 2, 4, {4}, {}, 0),
];
