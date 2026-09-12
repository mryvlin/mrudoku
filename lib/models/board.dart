import 'cell.dart';
import 'puzzle_shape.dart';

/// Side length of the classic Sudoku grid, and of one of its 3x3 boxes.
/// Still meaningful for classic-only code (box arithmetic in the UI layer)
/// even though solving logic reads its unit structure from [Board.shape]
/// instead, since a non-classic shape (Samurai) has no single fixed size.
const int kBoardSize = 9;
const int kBoxSize = 3;

/// The (row, col) of the top-left cell of the 3x3 box containing (row, col),
/// on a classic 9x9 board.
(int, int) boxOrigin(int row, int col) => (row ~/ kBoxSize * kBoxSize, col ~/ kBoxSize * kBoxSize);

/// True if (r1, c1) and (r2, c2) fall in the same 3x3 box, on a classic 9x9
/// board.
bool sameBox(int r1, int c1, int r2, int c2) =>
    r1 ~/ kBoxSize == r2 ~/ kBoxSize && c1 ~/ kBoxSize == c2 ~/ kBoxSize;

/// 0-based index (0-8, left-to-right then top-to-bottom) of the 3x3 box
/// containing (row, col), on a classic 9x9 board.
int boxIndexOf(int row, int col) => (row ~/ kBoxSize) * kBoxSize + (col ~/ kBoxSize);

/// Immutable Sudoku board made up of [Cell]s, over whatever coordinate space
/// [shape] defines - a classic 9x9 grid by default, or a larger, possibly
/// non-rectangular shape such as Samurai's cross of five overlapping grids.
///
/// Pure Dart, no Flutter dependency, so it can be unit-tested and reused by
/// both the solver/generator and the UI layer.
class Board {
  /// `grid[row][col]`, sized `shape.height` x `shape.width`. A coordinate
  /// outside `shape.activeCells` holds an inert, always-empty [Cell] that's
  /// never read by any active-cell scan.
  final List<List<Cell>> grid;
  final PuzzleShape shape;

  Board(this.grid, {PuzzleShape? shape}) : shape = shape ?? PuzzleShape.classic {
    assert(grid.length == this.shape.height);
    assert(grid.every((row) => row.length == this.shape.width));
  }

  factory Board.empty([PuzzleShape? shape]) {
    final s = shape ?? PuzzleShape.classic;
    return Board(
      List.generate(s.height, (_) => List.generate(s.width, (_) => const Cell())),
      shape: s,
    );
  }

  /// Builds a board from raw digit values (0 = empty). Every non-zero cell
  /// is marked as a "given" unless [givenMask] says otherwise. A coordinate
  /// outside [shape]'s active cells is ignored gameplay-wise but must still
  /// have an entry (typically 0) in [values], since it's a plain
  /// `shape.height` x `shape.width` rectangle.
  factory Board.fromValues(List<List<int>> values, {List<List<bool>>? givenMask, PuzzleShape? shape}) {
    final s = shape ?? PuzzleShape.classic;
    return Board(
      List.generate(
        s.height,
        (r) => List.generate(
          s.width,
          (c) => Cell(
            value: values[r][c],
            isGiven: givenMask != null ? givenMask[r][c] : values[r][c] != 0,
          ),
        ),
      ),
      shape: s,
    );
  }

  Cell cellAt(int row, int col) => grid[row][col];

  /// Returns a new board with the cell at (row, col) replaced.
  Board setCell(int row, int col, Cell cell) {
    final newGrid = [
      for (var r = 0; r < shape.height; r++)
        r == row ? [...grid[r]] : grid[r],
    ];
    newGrid[row][col] = cell;
    return Board(newGrid, shape: shape);
  }

  /// The units (row, column, box - or more, at a Samurai shared-box cell)
  /// that (row, col) must satisfy.
  List<Unit> unitsContaining(int row, int col) => shape.unitsContaining(row, col);

  bool get isFull => shape.activeCells.every((pos) => !cellAt(pos.$1, pos.$2).isEmpty);

  Board clone() => Board([for (final row in grid) [for (final cell in row) cell]], shape: shape);

  List<List<int>> toValueGrid() => [for (final row in grid) [for (final cell in row) cell.value]];

  Map<String, dynamic> toJson() => {
        'grid': [
          for (final row in grid) [for (final cell in row) cell.toJson()],
        ],
      };

  /// [shape] is not itself persisted - a caller that knows the board isn't
  /// classic (see `GameState`'s `BoardLayout`) passes the right shape in.
  factory Board.fromJson(Map<String, dynamic> json, {PuzzleShape? shape}) {
    final rows = json['grid'] as List<dynamic>;
    return Board(
      [
        for (final row in rows)
          [for (final cellJson in row as List<dynamic>) Cell.fromJson(cellJson as Map<String, dynamic>)],
      ],
      shape: shape ?? PuzzleShape.classic,
    );
  }
}
