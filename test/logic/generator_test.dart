import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/logic/generator.dart';
import 'package:mrsudoku/logic/solver.dart';
import 'package:mrsudoku/models/difficulty.dart';

void main() {
  group('Generator', () {
    for (final difficulty in Difficulty.values) {
      test('generates a uniquely solvable puzzle for $difficulty', () {
        final generated = Generator.generate(difficulty, seed: 123);
        final puzzleGrid = generated.puzzle.toValueGrid();

        expect(Solver.hasUniqueSolution(puzzleGrid), isTrue);

        final resolved = Solver.solve(puzzleGrid);
        expect(resolved, equals(generated.solution.toValueGrid()));

        // Every minimal Sudoku puzzle needs at least 17 clues; anything
        // below that could never have a unique solution.
        final givenCount =
            generated.puzzle.grid.expand((row) => row).where((cell) => cell.isGiven).length;
        expect(givenCount, greaterThanOrEqualTo(17));
      });
    }

    test('is reproducible for a fixed seed', () {
      final a = Generator.generate(Difficulty.medium, seed: 42);
      final b = Generator.generate(Difficulty.medium, seed: 42);
      expect(a.puzzle.toValueGrid(), equals(b.puzzle.toValueGrid()));
      expect(a.solution.toValueGrid(), equals(b.solution.toValueGrid()));
    });
  });
}
