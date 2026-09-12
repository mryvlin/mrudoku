import 'puzzle_shape.dart';

/// Which physical arrangement of grids a game is played on.
enum BoardLayout { classic, samurai }

extension BoardLayoutX on BoardLayout {
  /// The [PuzzleShape] this layout is played on.
  PuzzleShape get shape {
    switch (this) {
      case BoardLayout.classic:
        return PuzzleShape.classic;
      case BoardLayout.samurai:
        return PuzzleShape.samurai;
    }
  }
}
