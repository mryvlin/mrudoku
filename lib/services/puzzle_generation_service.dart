import 'package:flutter/foundation.dart';

import '../logic/generator.dart';
import '../models/board.dart';
import '../models/board_layout.dart';
import '../models/difficulty.dart';

/// Message sent to the background isolate.
class _GenerationRequest {
  final Difficulty difficulty;
  final BoardLayout layout;
  final int? seed;
  const _GenerationRequest(this.difficulty, this.layout, this.seed);
}

/// Plain-data result sent back from the isolate. Only primitive grids are
/// used here (not [Board]/[Cell] directly) to keep the isolate boundary
/// simple and unambiguously safe to serialize.
class _GenerationResult {
  final List<List<int>> puzzleValues;
  final List<List<bool>> givenMask;
  final List<List<int>> solutionValues;
  const _GenerationResult(this.puzzleValues, this.givenMask, this.solutionValues);
}

/// Runs the pure-Dart [Generator] on a background isolate via `compute()`,
/// so puzzle generation never blocks the UI thread - most noticeable on
/// Hard/Expert, where uniqueness-preserving hole digging does substantial
/// backtracking.
class PuzzleGenerationService {
  const PuzzleGenerationService._();

  static Future<GeneratedPuzzle> generate(
    Difficulty difficulty, {
    BoardLayout layout = BoardLayout.classic,
    int? seed,
  }) async {
    final result = await compute(_generateInIsolate, _GenerationRequest(difficulty, layout, seed));
    final shape = layout.shape;
    return GeneratedPuzzle(
      puzzle: Board.fromValues(result.puzzleValues, givenMask: result.givenMask, shape: shape),
      solution: Board.fromValues(result.solutionValues, shape: shape),
      difficulty: difficulty,
    );
  }
}

/// Top-level entry point required by `compute()`. Must not be a closure.
_GenerationResult _generateInIsolate(_GenerationRequest request) {
  final generated = Generator.generate(request.difficulty, layout: request.layout, seed: request.seed);
  return _GenerationResult(
    generated.puzzle.toValueGrid(),
    [for (final row in generated.puzzle.grid) [for (final cell in row) cell.isGiven]],
    generated.solution.toValueGrid(),
  );
}
