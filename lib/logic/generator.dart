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
    //    logically easier than intended, retry with a different removal
    //    order - a handful of attempts is enough in practice.
    const maxAttempts = 5;
    Board bestPuzzle = Board.fromValues(solutionGrid);
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final puzzle = _digHoles(solutionGrid, difficulty, random);
      bestPuzzle = puzzle;
      if (difficulty == Difficulty.easy) break; // clue count alone suffices
      final rating = HintEngine.rateDifficulty(puzzle);
      if (rating.rank >= difficulty.maxAllowedTechniqueRank) break;
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
