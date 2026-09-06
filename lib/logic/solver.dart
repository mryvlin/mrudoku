import 'dart:math';

import '../models/board.dart';

/// Plain 9x9 digit grid (0 = empty), the representation the backtracking
/// solver operates on. Kept separate from [Board] because it is much
/// cheaper to mutate in place during the search.
typedef Grid = List<List<int>>;

/// Backtracking Sudoku solver, used both to generate fresh puzzles (a
/// randomized full solve starting from an empty grid) and to verify that a
/// puzzle has exactly one solution.
class Solver {
  const Solver._();

  static Grid emptyGrid() => List.generate(kBoardSize, (_) => List.filled(kBoardSize, 0));

  static Grid cloneGrid(Grid grid) => [for (final row in grid) [...row]];

  static bool _isSafe(Grid grid, int row, int col, int value) {
    for (var i = 0; i < kBoardSize; i++) {
      if (grid[row][i] == value || grid[i][col] == value) return false;
    }
    final (boxRow, boxCol) = boxOrigin(row, col);
    for (var r = boxRow; r < boxRow + kBoxSize; r++) {
      for (var c = boxCol; c < boxCol + kBoxSize; c++) {
        if (grid[r][c] == value) return false;
      }
    }
    return true;
  }

  /// First empty cell in row-major order, or `null` if the grid is full.
  static List<int>? _firstEmpty(Grid grid) {
    for (var r = 0; r < kBoardSize; r++) {
      for (var c = 0; c < kBoardSize; c++) {
        if (grid[r][c] == 0) return [r, c];
      }
    }
    return null;
  }

  /// Fills [grid] in place via backtracking, trying candidate values in
  /// randomized order at each step. Used to build a fresh, fully solved
  /// board from an empty grid. Returns `true` on success.
  static bool fillRandomized(Grid grid, Random random) {
    final pos = _firstEmpty(grid);
    if (pos == null) return true;
    final row = pos[0], col = pos[1];
    final values = List.generate(kBoardSize, (i) => i + 1)..shuffle(random);
    for (final value in values) {
      if (_isSafe(grid, row, col, value)) {
        grid[row][col] = value;
        if (fillRandomized(grid, random)) return true;
        grid[row][col] = 0;
      }
    }
    return false;
  }

  /// Deterministic backtracking solve (smallest value first). Returns a new
  /// solved grid, or `null` if [grid] is unsolvable.
  static Grid? solve(Grid grid) {
    final working = cloneGrid(grid);
    return _solveInPlace(working) ? working : null;
  }

  static bool _solveInPlace(Grid grid) {
    final pos = _firstEmpty(grid);
    if (pos == null) return true;
    final row = pos[0], col = pos[1];
    for (var value = 1; value <= kBoardSize; value++) {
      if (_isSafe(grid, row, col, value)) {
        grid[row][col] = value;
        if (_solveInPlace(grid)) return true;
        grid[row][col] = 0;
      }
    }
    return false;
  }

  /// Counts distinct solutions of [grid], stopping as soon as [limit] is
  /// reached. Used for uniqueness checks: a puzzle is uniquely solvable iff
  /// `countSolutions(grid, limit: 2) == 1`.
  static int countSolutions(Grid grid, {int limit = 2}) {
    final working = cloneGrid(grid);
    var count = 0;

    bool search() {
      final pos = _firstEmpty(working);
      if (pos == null) {
        count++;
        return count >= limit;
      }
      final row = pos[0], col = pos[1];
      for (var value = 1; value <= kBoardSize; value++) {
        if (_isSafe(working, row, col, value)) {
          working[row][col] = value;
          final stop = search();
          working[row][col] = 0;
          if (stop) return true;
        }
      }
      return false;
    }

    search();
    return count;
  }

  static bool hasUniqueSolution(Grid grid) => countSolutions(grid, limit: 2) == 1;
}
