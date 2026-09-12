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

  /// Number of given cells the generator aims to keep, for [layout].
  /// Tuned empirically against `Solver`'s minimum-remaining-values search:
  /// below roughly 110-115 clues, Samurai's hole-digging cost still spikes
  /// non-linearly (seen up to ~90s on some seeds even after that search
  /// upgrade), so these stay a comfortable margin above that cliff while
  /// still landing on the hardest allowed technique a large fraction of the
  /// time once `Generator` retries for the hardest attempt within the cap.
  int clueCountFor(BoardLayout layout) {
    switch (layout) {
      case BoardLayout.classic:
        return clueCount;
      case BoardLayout.samurai:
        switch (this) {
          case Difficulty.easy:
            return 190;
          case Difficulty.medium:
            return 155;
          case Difficulty.hard:
            return 130;
          case Difficulty.expert:
            return 122;
        }
      case BoardLayout.twin:
        // Twin's 153 active cells generate fast even at low clue counts (no
        // cliff found down to 40 in testing), so these track classic's
        // clue/cell ratio closely rather than needing Samurai's safety
        // margin above a timing cliff.
        switch (this) {
          case Difficulty.easy:
            return 80;
          case Difficulty.medium:
            return 64;
          case Difficulty.hard:
            return 53;
          case Difficulty.expert:
            return 46;
        }
      case BoardLayout.gattai8:
        // 576 active cells - bigger than Samurai's, so its own cliff sits
        // higher too (found starting around 171 in testing); these stay a
        // margin above it.
        switch (this) {
          case Difficulty.easy:
            return 300;
          case Difficulty.medium:
            return 242;
          case Difficulty.hard:
            return 199;
          case Difficulty.expert:
            return 178;
        }
      case BoardLayout.sohei:
        // 288 active cells; its cliff starts somewhere below 85 in testing
        // (a run at 75 didn't finish), so these stay above that.
        switch (this) {
          case Difficulty.easy:
            return 150;
          case Difficulty.medium:
            return 121;
          case Difficulty.hard:
            return 100;
          case Difficulty.expert:
            return 85;
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
