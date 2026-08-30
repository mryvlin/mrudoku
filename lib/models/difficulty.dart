/// Available difficulty levels for a new game.
enum Difficulty { easy, medium, hard, expert }

extension DifficultyX on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.easy:
        return 'Einfach';
      case Difficulty.medium:
        return 'Mittel';
      case Difficulty.hard:
        return 'Schwer';
      case Difficulty.expert:
        return 'Experte';
    }
  }

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
  /// (for easy/medium) too hard. See [SolvingTechnique] for the ordering.
  int get maxAllowedTechniqueRank {
    switch (this) {
      case Difficulty.easy:
        return 0; // naked single only
      case Difficulty.medium:
        return 1; // up to hidden single
      case Difficulty.hard:
        return 2; // up to naked/hidden pair
      case Difficulty.expert:
        return 3; // pointing pairs and beyond, or backtracking
    }
  }
}
