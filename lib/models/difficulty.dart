import 'board_layout.dart';

/// Available difficulty levels for a new game.
enum Difficulty { easy, medium, hard, expert }

extension DifficultyX on Difficulty {
  /// Number of given (pre-filled) cells the generator aims to keep on a
  /// classic 9x9 board. Lower clue counts require harder solving techniques
  /// and more backtracking during generation.
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

  /// Number of given cells the generator aims to keep, for [layout]. A
  /// Samurai board (369 active cells across its 5 overlapping grids) needs
  /// proportionally far more givens than [clueCount]'s classic numbers
  /// scaled up would suggest, to stay solvable/generatable in reasonable
  /// time - the interlocking shared boxes make low clue counts much more
  /// expensive to dig holes into than an equivalent-ratio classic board.
  int clueCountFor(BoardLayout layout) {
    switch (layout) {
      case BoardLayout.classic:
        return clueCount;
      case BoardLayout.samurai:
        switch (this) {
          case Difficulty.easy:
            return 220;
          case Difficulty.medium:
            return 190;
          case Difficulty.hard:
            return 160;
          case Difficulty.expert:
            return 140;
        }
    }
  }

  /// The hardest solving technique a puzzle of this difficulty is allowed to
  /// require. The generator retries a hole layout that comes out needing
  /// anything harder than this - most relevant at low clue counts (Hard,
  /// Expert), where a random layout can easily force techniques well beyond
  /// what the difficulty promises. See `SolvingTechnique` in hint_engine.dart
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
        return 8; // hidden pair, naked triple, X-Wing, XY-Wing, Swordfish and beyond, or backtracking
    }
  }
}
