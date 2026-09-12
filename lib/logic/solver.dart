import 'dart:math';

import '../models/board.dart';
import '../models/puzzle_shape.dart';

/// Plain digit grid (0 = empty), the representation the backtracking
/// solver operates on. Kept separate from [Board] because it is much
/// cheaper to mutate in place during the search. Sized to whichever
/// [PuzzleShape] is passed to each method (defaults to classic 9x9); a
/// coordinate outside the shape's active cells is simply never read.
typedef Grid = List<List<int>>;

/// Backtracking Sudoku solver, used both to generate fresh puzzles (a
/// randomized full solve starting from an empty grid) and to verify that a
/// puzzle has exactly one solution. Shape-agnostic: it only ever asks a
/// [PuzzleShape] "which cells are active" and "which units does this cell
/// need to satisfy," so the same backtracking logic proves uniqueness for
/// a classic 9x9 board or a multi-grid layout like Samurai alike.
class Solver {
  const Solver._();

  static Grid emptyGrid([PuzzleShape? shape]) {
    final s = shape ?? PuzzleShape.classic;
    return List.generate(s.height, (_) => List.filled(s.width, 0));
  }

  static Grid cloneGrid(Grid grid) => [for (final row in grid) [...row]];

  static bool _isSafe(Grid grid, PuzzleShape shape, int row, int col, int value) {
    for (final unit in shape.unitsContaining(row, col)) {
      for (final (r, c) in unit.cells) {
        if ((r != row || c != col) && grid[r][c] == value) return false;
      }
    }
    return true;
  }

  /// First empty active cell (shape-defined iteration order), or `null` if
  /// every active cell is filled.
  static List<int>? _firstEmpty(Grid grid, PuzzleShape shape) {
    for (final (r, c) in shape.activeCells) {
      if (grid[r][c] == 0) return [r, c];
    }
    return null;
  }

  /// Fills [grid] in place via backtracking, trying candidate values in
  /// randomized order at each step. Used to build a fresh, fully solved
  /// board from an empty grid. Returns `true` on success.
  static bool fillRandomized(Grid grid, Random random, [PuzzleShape? shape]) {
    final s = shape ?? PuzzleShape.classic;
    final pos = _firstEmpty(grid, s);
    if (pos == null) return true;
    final row = pos[0], col = pos[1];
    final values = List.generate(kBoardSize, (i) => i + 1)..shuffle(random);
    for (final value in values) {
      if (_isSafe(grid, s, row, col, value)) {
        grid[row][col] = value;
        if (fillRandomized(grid, random, s)) return true;
        grid[row][col] = 0;
      }
    }
    return false;
  }

  /// Deterministic backtracking solve (smallest value first). Returns a new
  /// solved grid, or `null` if [grid] is unsolvable.
  static Grid? solve(Grid grid, [PuzzleShape? shape]) {
    final s = shape ?? PuzzleShape.classic;
    final working = cloneGrid(grid);
    return _solveInPlace(working, s) ? working : null;
  }

  static bool _solveInPlace(Grid grid, PuzzleShape shape) {
    final pos = _firstEmpty(grid, shape);
    if (pos == null) return true;
    final row = pos[0], col = pos[1];
    for (var value = 1; value <= kBoardSize; value++) {
      if (_isSafe(grid, shape, row, col, value)) {
        grid[row][col] = value;
        if (_solveInPlace(grid, shape)) return true;
        grid[row][col] = 0;
      }
    }
    return false;
  }

  /// Counts distinct solutions of [grid], stopping as soon as [limit] is
  /// reached. Used for uniqueness checks: a puzzle is uniquely solvable iff
  /// `countSolutions(grid, limit: 2) == 1`.
  static int countSolutions(Grid grid, {int limit = 2, PuzzleShape? shape}) {
    final s = shape ?? PuzzleShape.classic;
    final working = cloneGrid(grid);
    var count = 0;

    bool search() {
      final pos = _firstEmpty(working, s);
      if (pos == null) {
        count++;
        return count >= limit;
      }
      final row = pos[0], col = pos[1];
      for (var value = 1; value <= kBoardSize; value++) {
        if (_isSafe(working, s, row, col, value)) {
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

  static bool hasUniqueSolution(Grid grid, [PuzzleShape? shape]) =>
      countSolutions(grid, limit: 2, shape: shape) == 1;
}
