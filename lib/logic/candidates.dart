import '../models/board.dart';

/// Computes legal candidate values (1-9) for a cell, based purely on which
/// digits already occupy the same row, column and box - the cell's own
/// current value (if any) never counts against itself, so a cell holding a
/// wrong guess still reports the candidates it would have if it were empty
/// (callers that only care about empty cells, such as [HintEngine] and
/// `GameController.autoFillNotes`, filter those out separately).
class Candidates {
  const Candidates._();

  static Set<int> forCell(Board board, int row, int col) {
    final ownValue = board.cellAt(row, col).value;
    final used = <int>{
      for (final unit in board.unitsContaining(row, col))
        for (final (r, c) in unit.cells) board.cellAt(r, c).value,
    }
      ..remove(0)
      ..remove(ownValue);
    return {for (var v = 1; v <= kBoardSize; v++) if (!used.contains(v)) v};
  }

  /// Candidate sets for every cell of the board. Callers that only want
  /// candidates for empty cells (all current ones) must filter by
  /// `Board.cellAt(r, c).isEmpty` themselves - see the class doc above.
  static List<List<Set<int>>> forBoard(Board board) => [
        for (var r = 0; r < board.shape.height; r++)
          [for (var c = 0; c < board.shape.width; c++) forCell(board, r, c)],
      ];
}
