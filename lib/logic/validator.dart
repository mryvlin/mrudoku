import '../models/board.dart';

/// Pure Sudoku rule validation: does a value clash with row/column/box, and
/// is a fully filled board actually a correct solution.
class Validator {
  const Validator._();

  /// Returns the set of (row, col) positions that currently conflict with
  /// the cell at (row, col) for the given [value] (row, column and box).
  /// Empty cells (value == 0) never conflict.
  static Set<(int, int)> conflictsFor(Board board, int row, int col, int value) {
    if (value == 0) return const {};
    final conflicts = <(int, int)>{};

    for (var c = 0; c < kBoardSize; c++) {
      if (c != col && board.cellAt(row, c).value == value) conflicts.add((row, c));
    }
    for (var r = 0; r < kBoardSize; r++) {
      if (r != row && board.cellAt(r, col).value == value) conflicts.add((r, col));
    }
    final (boxRow, boxCol) = boxOrigin(row, col);
    for (var r = boxRow; r < boxRow + kBoxSize; r++) {
      for (var c = boxCol; c < boxCol + kBoxSize; c++) {
        if ((r != row || c != col) && board.cellAt(r, c).value == value) conflicts.add((r, c));
      }
    }
    return conflicts;
  }

  /// `true` if placing [value] at (row, col) would break Sudoku rules given
  /// the current board state.
  static bool isValidPlacement(Board board, int row, int col, int value) {
    return conflictsFor(board, row, col, value).isEmpty;
  }

  /// Returns every (row, col) pair in the whole board that currently
  /// violates a row/column/box uniqueness rule. Useful for a full-board
  /// error overlay.
  static Set<(int, int)> allConflicts(Board board) {
    final conflicts = <(int, int)>{};
    for (var r = 0; r < kBoardSize; r++) {
      for (var c = 0; c < kBoardSize; c++) {
        final value = board.cellAt(r, c).value;
        if (value == 0) continue;
        if (conflictsFor(board, r, c, value).isNotEmpty) conflicts.add((r, c));
      }
    }
    return conflicts;
  }

  /// `true` if the board is completely filled and satisfies all Sudoku
  /// rules, i.e. the puzzle is solved.
  static bool isSolved(Board board) {
    if (!board.isFull) return false;
    return allConflicts(board).isEmpty;
  }
}
