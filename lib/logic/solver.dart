import 'dart:math';

import '../models/board.dart';
import '../models/puzzle_shape.dart';

/// Plain digit grid (0 = empty), the representation the backtracking
/// solver operates on. Kept separate from [Board] because it is much
/// cheaper to mutate in place during the search. Sized to whichever
/// [PuzzleShape] is passed to each method (defaults to classic 9x9); a
/// coordinate outside the shape's active cells is simply never read.
typedef Grid = List<List<int>>;

/// Live per-cell candidate sets for one in-progress backtracking search,
/// updated incrementally as values are placed/undone instead of being
/// recomputed from every empty cell's units on every recursive call - the
/// difference between O(peers) and O(every empty cell x its units) per
/// step, which is what still made hole-digging on a large board (Gattai-8's
/// 576 cells) slow even after [Solver] started picking the most-constrained
/// cell first: that heuristic still recomputed every cell's candidates from
/// scratch to decide which one was most constrained.
class _Candidates {
  final PuzzleShape shape;
  final List<List<Set<int>>> byCell;

  _Candidates(Grid grid, this.shape)
      : byCell = List.generate(shape.height, (_) => List.generate(shape.width, (_) => <int>{})) {
    for (final (r, c) in shape.activeCells) {
      if (grid[r][c] != 0) continue;
      final used = <int>{
        for (final unit in shape.unitsContaining(r, c))
          for (final (ur, uc) in unit.cells)
            if (grid[ur][uc] != 0) grid[ur][uc],
      };
      byCell[r][c] = {for (var v = 1; v <= kBoardSize; v++) if (!used.contains(v)) v};
    }
  }

  /// Removes [value] from every empty peer's candidates, returning exactly
  /// the peers it was actually removed from - pass back to [undo] to
  /// restore them when backtracking out of this placement.
  List<(int, int)> place(int row, int col, int value) {
    final touched = <(int, int)>[];
    for (final (r, c) in shape.peersByCell[(row, col)] ?? const <(int, int)>[]) {
      if (byCell[r][c].remove(value)) touched.add((r, c));
    }
    return touched;
  }

  void undo(int value, List<(int, int)> touched) {
    for (final (r, c) in touched) {
      byCell[r][c].add(value);
    }
  }

  /// The empty active cell with the fewest legal candidates left (the
  /// "minimum remaining values" heuristic): a cell already down to zero is
  /// returned immediately, failing this branch right away instead of
  /// discovering the dead end many cells later; a cell down to exactly one
  /// is a forced move, found and filled before any guessing happens. Both
  /// cut the search tree far more than picking cells in a fixed order ever
  /// could. `null` once every active cell is filled.
  (int, int)? mostConstrainedEmpty(Grid grid) {
    (int, int)? best;
    var bestCount = kBoardSize + 1;
    for (final (r, c) in shape.activeCells) {
      if (grid[r][c] != 0) continue;
      final count = byCell[r][c].length;
      if (count == 0) return (r, c);
      if (count < bestCount) {
        bestCount = count;
        best = (r, c);
        if (bestCount == 1) break;
      }
    }
    return best;
  }
}

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

  /// Fills [grid] in place via backtracking, trying candidate values in
  /// randomized order at each step. Used to build a fresh, fully solved
  /// board from an empty grid. Returns `true` on success.
  static bool fillRandomized(Grid grid, Random random, [PuzzleShape? shape]) {
    final s = shape ?? PuzzleShape.classic;
    return _fill(grid, random, s, _Candidates(grid, s));
  }

  static bool _fill(Grid grid, Random random, PuzzleShape shape, _Candidates cands) {
    final pos = cands.mostConstrainedEmpty(grid);
    if (pos == null) return true;
    final (row, col) = pos;
    final values = cands.byCell[row][col].toList()..shuffle(random);
    for (final value in values) {
      grid[row][col] = value;
      final touched = cands.place(row, col, value);
      if (_fill(grid, random, shape, cands)) return true;
      cands.undo(value, touched);
      grid[row][col] = 0;
    }
    return false;
  }

  /// Deterministic backtracking solve (smallest value first). Returns a new
  /// solved grid, or `null` if [grid] is unsolvable.
  static Grid? solve(Grid grid, [PuzzleShape? shape]) {
    final s = shape ?? PuzzleShape.classic;
    final working = cloneGrid(grid);
    return _solveInPlace(working, s, _Candidates(working, s)) ? working : null;
  }

  static bool _solveInPlace(Grid grid, PuzzleShape shape, _Candidates cands) {
    final pos = cands.mostConstrainedEmpty(grid);
    if (pos == null) return true;
    final (row, col) = pos;
    // Candidate sets are built in ascending order (see _Candidates) and
    // never reordered, so this already tries the smallest value first.
    for (final value in cands.byCell[row][col].toList()) {
      grid[row][col] = value;
      final touched = cands.place(row, col, value);
      if (_solveInPlace(grid, shape, cands)) return true;
      cands.undo(value, touched);
      grid[row][col] = 0;
    }
    return false;
  }

  /// Counts distinct solutions of [grid], stopping as soon as [limit] is
  /// reached. Used for uniqueness checks: a puzzle is uniquely solvable iff
  /// `countSolutions(grid, limit: 2) == 1`.
  static int countSolutions(Grid grid, {int limit = 2, PuzzleShape? shape}) {
    final s = shape ?? PuzzleShape.classic;
    final working = cloneGrid(grid);
    final cands = _Candidates(working, s);
    var count = 0;

    bool search() {
      final pos = cands.mostConstrainedEmpty(working);
      if (pos == null) {
        count++;
        return count >= limit;
      }
      final (row, col) = pos;
      for (final value in cands.byCell[row][col].toList()) {
        working[row][col] = value;
        final touched = cands.place(row, col, value);
        final stop = search();
        cands.undo(value, touched);
        working[row][col] = 0;
        if (stop) return true;
      }
      return false;
    }

    search();
    return count;
  }

  static bool hasUniqueSolution(Grid grid, [PuzzleShape? shape]) =>
      countSolutions(grid, limit: 2, shape: shape) == 1;
}
