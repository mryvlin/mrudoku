import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/logic/generator.dart';
import 'package:mrsudoku/logic/hint_engine.dart';
import 'package:mrsudoku/logic/solver.dart';
import 'package:mrsudoku/models/board_layout.dart';
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
    // needing backtracking (the highest rank) despite a documented cap of 2. Sample
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

  group('Generator - Samurai layout', () {
    final shape = BoardLayout.samurai.shape;

    for (final difficulty in Difficulty.values) {
      test('generates a uniquely solvable Samurai puzzle for $difficulty within a few seconds', () {
        final stopwatch = Stopwatch()..start();
        final generated = Generator.generate(difficulty, layout: BoardLayout.samurai, seed: 7);
        stopwatch.stop();

        // Hole-digging cost grows steeply as the clue count target drops
        // (an empirical check during development found generation time
        // exploding well past a minute below ~120 clues) - this is a loose
        // sanity bound on the tuned constants in Difficulty.clueCountFor,
        // not a strict performance contract.
        expect(stopwatch.elapsedMilliseconds, lessThan(15000));

        final puzzleGrid = generated.puzzle.toValueGrid();
        expect(Solver.hasUniqueSolution(puzzleGrid, shape), isTrue);

        final resolved = Solver.solve(puzzleGrid, shape);
        expect(resolved, isNotNull);
        for (final (r, c) in shape.activeCells) {
          expect(resolved![r][c], generated.solution.cellAt(r, c).value);
        }

        // Digging stops once the target is reached, but a position can be
        // left un-dug if removing it would break uniqueness - so the clue
        // count can come out at or above the target, never below it.
        final givenCount =
            shape.activeCells.where((pos) => generated.puzzle.cellAt(pos.$1, pos.$2).isGiven).length;
        expect(givenCount, greaterThanOrEqualTo(difficulty.clueCountFor(BoardLayout.samurai)));
      });
    }

    test('is reproducible for a fixed seed', () {
      final a = Generator.generate(Difficulty.medium, layout: BoardLayout.samurai, seed: 42);
      final b = Generator.generate(Difficulty.medium, layout: BoardLayout.samurai, seed: 42);
      expect(a.puzzle.toValueGrid(), equals(b.puzzle.toValueGrid()));
      expect(a.solution.toValueGrid(), equals(b.solution.toValueGrid()));
    });
  });
}
