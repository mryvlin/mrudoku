import 'cell.dart';

/// Side length of the Sudoku grid.
const int kBoardSize = 9;

/// Side length of a single 3x3 box.
const int kBoxSize = 3;

/// The (row, col) of the top-left cell of the 3x3 box containing (row, col).
/// The single place this arithmetic lives - solver.dart, validator.dart,
/// GameController and the board/hint UI all used to compute it separately.
(int, int) boxOrigin(int row, int col) => (row ~/ kBoxSize * kBoxSize, col ~/ kBoxSize * kBoxSize);

/// True if (r1, c1) and (r2, c2) fall in the same 3x3 box.
bool sameBox(int r1, int c1, int r2, int c2) =>
    r1 ~/ kBoxSize == r2 ~/ kBoxSize && c1 ~/ kBoxSize == c2 ~/ kBoxSize;

/// 0-based index (0-8, left-to-right then top-to-bottom) of the 3x3 box
/// containing (row, col).
int boxIndexOf(int row, int col) => (row ~/ kBoxSize) * kBoxSize + (col ~/ kBoxSize);

/// Immutable 9x9 Sudoku board made up of [Cell]s.
///
/// Pure Dart, no Flutter dependency, so it can be unit-tested and reused by
/// both the solver/generator and the UI layer.
class Board {
  /// `grid[row][col]`, both 0-indexed (0-8).
  final List<List<Cell>> grid;

  Board(this.grid)
      : assert(grid.length == kBoardSize),
        assert(grid.every((row) => row.length == kBoardSize));

  factory Board.empty() => Board(List.generate(
        kBoardSize,
        (_) => List.generate(kBoardSize, (_) => const Cell()),
      ));

  /// Builds a board from raw digit values (0 = empty). Every non-zero cell
  /// is marked as a "given" unless [givenMask] says otherwise.
  factory Board.fromValues(List<List<int>> values, {List<List<bool>>? givenMask}) {
    return Board(List.generate(
      kBoardSize,
      (r) => List.generate(
        kBoardSize,
        (c) => Cell(
          value: values[r][c],
          isGiven: givenMask != null ? givenMask[r][c] : values[r][c] != 0,
        ),
      ),
    ));
  }

  Cell cellAt(int row, int col) => grid[row][col];

  /// Returns a new board with the cell at (row, col) replaced.
  Board setCell(int row, int col, Cell cell) {
    final newGrid = [
      for (var r = 0; r < kBoardSize; r++)
        r == row ? [...grid[r]] : grid[r],
    ];
    newGrid[row][col] = cell;
    return Board(newGrid);
  }

  List<Cell> rowCells(int row) => grid[row];

  List<Cell> columnCells(int col) => [for (var r = 0; r < kBoardSize; r++) grid[r][col]];

  List<Cell> boxCells(int boxRow, int boxCol) => [
        for (var r = boxRow * kBoxSize; r < boxRow * kBoxSize + kBoxSize; r++)
          for (var c = boxCol * kBoxSize; c < boxCol * kBoxSize + kBoxSize; c++) grid[r][c],
      ];

  List<Cell> boxCellsContaining(int row, int col) =>
      boxCells(row ~/ kBoxSize, col ~/ kBoxSize);

  bool get isFull => grid.every((row) => row.every((cell) => !cell.isEmpty));

  Board clone() => Board([for (final row in grid) [for (final cell in row) cell]]);

  List<List<int>> toValueGrid() => [for (final row in grid) [for (final cell in row) cell.value]];

  Map<String, dynamic> toJson() => {
        'grid': [
          for (final row in grid) [for (final cell in row) cell.toJson()],
        ],
      };

  factory Board.fromJson(Map<String, dynamic> json) {
    final rows = json['grid'] as List<dynamic>;
    return Board([
      for (final row in rows)
        [for (final cellJson in row as List<dynamic>) Cell.fromJson(cellJson as Map<String, dynamic>)],
    ]);
  }
}
