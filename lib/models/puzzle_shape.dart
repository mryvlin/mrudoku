/// Which kind of Sudoku constraint a [Unit] represents - purely for
/// labeling (e.g. a hidden-single hint naming "row 3" vs "box 5"), since
/// every unit is checked identically (its 9 cells must contain 1-9 exactly
/// once) regardless of kind.
enum UnitKind { row, column, box }

/// One group of exactly 9 cells that must contain the digits 1-9 exactly
/// once. Rows, columns and boxes are represented uniformly so solving logic
/// never needs to assume "each cell has exactly one row, one column and one
/// box" - a cell can belong to more than 3 units (a Samurai shared-box cell
/// belongs to two row units and two column units, one from each of the two
/// grids it's part of, plus one shared box unit).
class Unit {
  final UnitKind kind;

  /// Exactly 9 `(row, col)` pairs, in the shape's global coordinate space.
  final List<(int, int)> cells;

  /// Which of the shape's constituent 9x9 grids this unit belongs to
  /// (0 for classic's single grid; 0-4 for Samurai's five grids, in the
  /// order they're defined). Row and column units are never shared between
  /// grids, so this is unambiguous for them - it's what lets X-Wing/
  /// Swordfish group a grid's own rows/columns together instead of
  /// conflating two different grids' units that happen to share a global
  /// row/column number. A box unit shared between two grids simply keeps
  /// whichever grid defined it first; nothing relies on a shared box's
  /// gridId.
  final int gridId;

  const Unit(this.kind, this.cells, this.gridId) : assert(cells.length == 9);
}

/// Defines the shape of a Sudoku puzzle: which `(row, col)` coordinates (in
/// one shared global coordinate space) are real, playable cells, and which
/// groups of 9 cells ("units") must each contain 1-9 exactly once.
///
/// Every place that used to assume "a board is a 9x9 grid with 3x3 boxes
/// tiled 3x3" - `Solver`, `Validator`, `Candidates`, `HintEngine`,
/// `Generator` - reads that structure from a `PuzzleShape` instead, so a
/// non-rectangular, multi-grid layout (Samurai) is just a different
/// `PuzzleShape`, not a separate implementation of any of those.
class PuzzleShape {
  final int height;
  final int width;
  final Set<(int, int)> activeCells;
  final List<Unit> units;
  final Map<(int, int), List<Unit>> unitsByCell;

  /// Every ordered pair of *distinct* units sharing at least 2 cells -
  /// computed once per shape (there are only ever a few hundred units, so
  /// this is a one-off O(units^2) cost at startup) since it never changes
  /// afterwards. In a classic board this is always a box paired with one of
  /// its own rows/columns; in Samurai a shared box additionally pairs with
  /// the second grid's row/column units through that same box. Powers
  /// `HintEngine`'s generalized pointing-pair / box-line-reduction rule
  /// without recomputing unit intersections on every hint lookup.
  final List<(Unit, Unit)> linkedUnitPairs;

  PuzzleShape._({
    required this.height,
    required this.width,
    required this.activeCells,
    required this.units,
  })  : unitsByCell = _buildUnitsByCell(units),
        linkedUnitPairs = _buildLinkedUnitPairs(units);

  static Map<(int, int), List<Unit>> _buildUnitsByCell(List<Unit> units) {
    final map = <(int, int), List<Unit>>{};
    for (final unit in units) {
      for (final cell in unit.cells) {
        map.putIfAbsent(cell, () => []).add(unit);
      }
    }
    return map;
  }

  static List<(Unit, Unit)> _buildLinkedUnitPairs(List<Unit> units) {
    final pairs = <(Unit, Unit)>[];
    for (var i = 0; i < units.length; i++) {
      for (var j = 0; j < units.length; j++) {
        if (i == j) continue;
        final shared = units[i].cells.toSet().intersection(units[j].cells.toSet());
        if (shared.length >= 2) pairs.add((units[i], units[j]));
      }
    }
    return pairs;
  }

  /// The units (row, column, box - or more, at a Samurai shared-box cell)
  /// that (row, col) must satisfy. Empty for a cell outside [activeCells].
  List<Unit> unitsContaining(int row, int col) => unitsByCell[(row, col)] ?? const [];

  /// One plain 9x9 grid with 3x3 boxes tiled 3x3 - identical in substance to
  /// the game's original hardcoded structure (see `kBoardSize`/`kBoxSize`
  /// in `board.dart`).
  static final PuzzleShape classic = _buildClassic();

  /// Five overlapping 9x9 grids arranged in a cross: a center grid plus one
  /// grid at each corner, each corner grid sharing its inner 3x3 box with
  /// the corresponding corner box of the center grid. The bounding box is
  /// 21x21; only 369 of its 441 cells are real (5*81 minus the 4 shared
  /// boxes' 9 cells each, which would otherwise be double-counted).
  static final PuzzleShape samurai = _buildSamurai();

  static PuzzleShape _buildClassic() => _buildFromGridOrigins(const [(0, 0)]);

  static PuzzleShape _buildSamurai() => _buildFromGridOrigins(const [
        (0, 0), // top-left
        (0, 12), // top-right
        (6, 6), // center
        (12, 0), // bottom-left
        (12, 12), // bottom-right
      ]);

  /// Builds a shape from a list of 9x9 grids, each placed by its top-left
  /// corner in the shared global coordinate space. A unit that comes out
  /// identical (same 9 cells) to one already added - which happens exactly
  /// when two grids share a 3x3 box - is only kept once.
  static PuzzleShape _buildFromGridOrigins(List<(int, int)> gridOrigins) {
    final activeCells = <(int, int)>{};
    final units = <Unit>[];
    final seenUnitCellSets = <String>{};

    void addUnit(UnitKind kind, List<(int, int)> cells, int gridId) {
      final sorted = [...cells]..sort((a, b) {
          final rowCmp = a.$1.compareTo(b.$1);
          return rowCmp != 0 ? rowCmp : a.$2.compareTo(b.$2);
        });
      if (!seenUnitCellSets.add(sorted.join(','))) return;
      units.add(Unit(kind, cells, gridId));
    }

    var maxRow = 0, maxCol = 0;
    for (var gridId = 0; gridId < gridOrigins.length; gridId++) {
      final (originRow, originCol) = gridOrigins[gridId];
      maxRow = [maxRow, originRow + 9].reduce((a, b) => a > b ? a : b);
      maxCol = [maxCol, originCol + 9].reduce((a, b) => a > b ? a : b);

      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          activeCells.add((originRow + r, originCol + c));
        }
      }
      for (var r = 0; r < 9; r++) {
        addUnit(UnitKind.row, [for (var c = 0; c < 9; c++) (originRow + r, originCol + c)], gridId);
      }
      for (var c = 0; c < 9; c++) {
        addUnit(UnitKind.column, [for (var r = 0; r < 9; r++) (originRow + r, originCol + c)], gridId);
      }
      for (var br = 0; br < 3; br++) {
        for (var bc = 0; bc < 3; bc++) {
          addUnit(
            UnitKind.box,
            [
              for (var r = br * 3; r < br * 3 + 3; r++)
                for (var c = bc * 3; c < bc * 3 + 3; c++) (originRow + r, originCol + c),
            ],
            gridId,
          );
        }
      }
    }

    return PuzzleShape._(height: maxRow, width: maxCol, activeCells: activeCells, units: units);
  }
}
