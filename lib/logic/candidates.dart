import '../models/board.dart';

/// Computes legal candidate values (1-9) for empty cells, based purely on
/// which digits already occupy the same row, column and box.
class Candidates {
  const Candidates._();

  static Set<int> forCell(Board board, int row, int col) {
    if (!board.cellAt(row, col).isEmpty) return const <int>{};
    final used = <int>{
      ...board.rowCells(row).map((c) => c.value),
      ...board.columnCells(col).map((c) => c.value),
      ...board.boxCellsContaining(row, col).map((c) => c.value),
    }..remove(0);
    return {for (var v = 1; v <= kBoardSize; v++) if (!used.contains(v)) v};
  }

  /// Candidate sets for every cell of the board (empty cells only get a
  /// non-empty set; filled cells get an empty set).
  static List<List<Set<int>>> forBoard(Board board) => [
        for (var r = 0; r < kBoardSize; r++)
          [for (var c = 0; c < kBoardSize; c++) forCell(board, r, c)],
      ];
}
