/// Available difficulty levels for a new game.
enum Difficulty { easy, medium, hard, expert }

extension DifficultyX on Difficulty {
  /// Number of given (pre-filled) cells the generator aims to keep. Lower
  /// clue counts require harder solving techniques and more backtracking
  /// during generation.
  int get clueCount {
    switch (this) {
      case Difficulty.easy:
        return 42;
      case Difficulty.medium:
        return 34;
      case Difficulty.hard:
        return 28;
      case Difficulty.expert:
        return 24;
    }
  }

  /// The hardest solving technique a puzzle of this difficulty is allowed to
  /// require, used by the generator to reject puzzles that are too easy or
  /// (for easy/medium) too hard. See `SolvingTechnique` in hint_engine.dart
  /// for the ordering; these numbers must track its enum indices (checked by
  /// a test) but are duplicated as plain ints here so this model doesn't
  /// depend on the logic layer.
  int get maxAllowedTechniqueRank {
    switch (this) {
      case Difficulty.easy:
        return 0; // naked single only
      case Difficulty.medium:
        return 1; // up to hidden single
      case Difficulty.hard:
        return 2; // up to naked/pointing pair or box-line reduction
      case Difficulty.expert:
        return 6; // hidden pair, naked triple, X-Wing and beyond, or backtracking
    }
  }
}
