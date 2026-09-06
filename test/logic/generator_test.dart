import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/logic/generator.dart';
import 'package:mrsudoku/logic/hint_engine.dart';
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

    // Regression test for a bug where the generator accepted the first dug
    // layout whose rank met-or-exceeded the difficulty's cap instead of
    // retrying when it exceeded it, so e.g. Hard puzzles could come out
    // needing backtracking (rank 6) despite a documented cap of 2. Sample
    // several seeds per non-easy difficulty since any single seed might
    // land within range by chance even with the bug present.
    for (final difficulty in [Difficulty.medium, Difficulty.hard, Difficulty.expert]) {
      test('never exceeds $difficulty\'s allowed technique rank, across many seeds', () {
        for (var seed = 0; seed < 20; seed++) {
          final generated = Generator.generate(difficulty, seed: seed);
          final rank = HintEngine.rateDifficulty(generated.puzzle).rank;
          expect(
            rank,
            lessThanOrEqualTo(difficulty.maxAllowedTechniqueRank),
            reason: 'seed $seed produced a $difficulty puzzle needing rank $rank',
          );
        }
      });
    }
  });
}
