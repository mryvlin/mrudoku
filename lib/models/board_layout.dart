import 'puzzle_shape.dart';

/// Which physical arrangement of grids a game is played on.
enum BoardLayout { classic, samurai, twin, gattai8, sohei }

extension BoardLayoutX on BoardLayout {
  /// The [PuzzleShape] this layout is played on.
  PuzzleShape get shape {
    switch (this) {
      case BoardLayout.classic:
        return PuzzleShape.classic;
      case BoardLayout.samurai:
        return PuzzleShape.samurai;
      case BoardLayout.twin:
        return PuzzleShape.twin;
      case BoardLayout.gattai8:
        return PuzzleShape.gattai8;
      case BoardLayout.sohei:
        return PuzzleShape.sohei;
    }
  }
}
