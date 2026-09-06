import 'dart:math';

import '../models/board.dart';
import '../models/difficulty.dart';
import 'hint_engine.dart';
import 'solver.dart';

/// A freshly generated puzzle: the board to hand to the player (only
/// `isGiven` cells filled in) plus the full solution for validation/hints.
class GeneratedPuzzle {
  final Board puzzle;
  final Board solution;
  final Difficulty difficulty;

  const GeneratedPuzzle({required this.puzzle, required this.solution, required this.difficulty});
}

/// Creates Sudoku puzzles with a guaranteed unique solution.
///
/// Pure Dart, no Flutter dependency, so it can run inside a background
/// isolate (see `PuzzleGenerationService`) without touching the UI thread -
/// generation, especially for Hard/Expert, involves a fair amount of
/// backtracking-based uniqueness checking.
class Generator {
  const Generator._();

  /// Generates a puzzle for [difficulty]. Passing [seed] makes the result
  /// reproducible, which is mainly useful for tests.
  static GeneratedPuzzle generate(Difficulty difficulty, {int? seed}) {
    final random = seed != null ? Random(seed) : Random();

    // 1. Build a fully solved, valid Sudoku grid via randomized backtracking.
    final solutionGrid = Solver.emptyGrid();
    final filled = Solver.fillRandomized(solutionGrid, random);
    assert(filled, 'A random fill from an empty grid should always succeed');
    final solutionBoard = Board.fromValues(solutionGrid);

    // 2. Dig holes (remove cells) while preserving a unique solution, aiming
    //    for the difficulty's target clue count. If the result turns out
    //    logically *harder* than the difficulty allows - a real risk at low
    //    clue counts, where a random hole layout can easily force advanced
    //    techniques or outright backtracking - retry with a different
    //    removal order; a handful of attempts is enough in practice. Among
    //    attempts that never land within the allowed range, keep the
    //    least-too-hard one rather than whichever was dug last, so a
    //    maxAttempts-exhausted fallback is still as close to correct as
    //    possible instead of essentially random.
    const maxAttempts = 5;
    Board bestPuzzle = Board.fromValues(solutionGrid);
    var bestRank = -1;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final puzzle = _digHoles(solutionGrid, difficulty, random);
      if (difficulty == Difficulty.easy) {
        bestPuzzle = puzzle;
        break; // clue count alone suffices
      }
      final rank = HintEngine.rateDifficulty(puzzle).rank;
      if (attempt == 0 || rank < bestRank) {
        bestPuzzle = puzzle;
        bestRank = rank;
      }
      if (rank <= difficulty.maxAllowedTechniqueRank) break; // within the allowed range
    }

    return GeneratedPuzzle(puzzle: bestPuzzle, solution: solutionBoard, difficulty: difficulty);
  }

  static Board _digHoles(Grid solutionGrid, Difficulty difficulty, Random random) {
    final working = Solver.cloneGrid(solutionGrid);
    final positions = [
      for (var r = 0; r < kBoardSize; r++)
        for (var c = 0; c < kBoardSize; c++) [r, c],
    ]..shuffle(random);

    var remaining = kBoardSize * kBoardSize;
    final targetClues = difficulty.clueCount;

    for (final pos in positions) {
      if (remaining <= targetClues) break;
      final r = pos[0], c = pos[1];
      final backup = working[r][c];
      working[r][c] = 0;
      if (Solver.hasUniqueSolution(working)) {
        remaining--;
      } else {
        working[r][c] = backup;
      }
    }

    return Board.fromValues(working);
  }
}
