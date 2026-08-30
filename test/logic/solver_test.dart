import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/logic/solver.dart';

bool _isValidCompleteGrid(List<List<int>> grid) {
  for (var i = 0; i < 9; i++) {
    if (grid[i].toSet().length != 9) return false;
    final col = [for (var r = 0; r < 9; r++) grid[r][i]];
    if (col.toSet().length != 9) return false;
  }
  for (var br = 0; br < 3; br++) {
    for (var bc = 0; bc < 3; bc++) {
      final box = <int>{};
      for (var r = br * 3; r < br * 3 + 3; r++) {
        for (var c = bc * 3; c < bc * 3 + 3; c++) {
          box.add(grid[r][c]);
        }
      }
      if (box.length != 9) return false;
    }
  }
  return true;
}

void main() {
  group('Solver', () {
    test('fillRandomized produces a full, valid grid', () {
      final grid = Solver.emptyGrid();
      final ok = Solver.fillRandomized(grid, Random(42));
      expect(ok, isTrue);
      expect(grid.every((row) => row.every((v) => v >= 1 && v <= 9)), isTrue);
      expect(_isValidCompleteGrid(grid), isTrue);
    });

    test('solve recovers the missing value of an almost-complete grid', () {
      final grid = Solver.emptyGrid();
      Solver.fillRandomized(grid, Random(1));
      final full = Solver.cloneGrid(grid);
      grid[0][0] = 0;

      final solved = Solver.solve(grid);

      expect(solved, isNotNull);
      expect(solved, equals(full));
    });

    test('countSolutions stops early once the limit is reached', () {
      final grid = Solver.emptyGrid(); // fully empty grid has many solutions
      expect(Solver.countSolutions(grid, limit: 2), 2);
    });

    test('hasUniqueSolution is true for a fully solved grid', () {
      final grid = Solver.emptyGrid();
      Solver.fillRandomized(grid, Random(7));
      expect(Solver.hasUniqueSolution(grid), isTrue);
    });

    test('hasUniqueSolution is false for an under-constrained puzzle', () {
      final grid = Solver.emptyGrid();
      Solver.fillRandomized(grid, Random(3));
      // Clearing most of the grid almost certainly destroys uniqueness.
      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          if (r > 1) grid[r][c] = 0;
        }
      }
      expect(Solver.hasUniqueSolution(grid), isFalse);
    });
  });
}
