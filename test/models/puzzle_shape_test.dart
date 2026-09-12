import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/models/puzzle_shape.dart';

void main() {
  group('PuzzleShape.classic', () {
    final shape = PuzzleShape.classic;

    test('is a 9x9 grid with every cell active', () {
      expect(shape.height, 9);
      expect(shape.width, 9);
      expect(shape.activeCells.length, 81);
    });

    test('has exactly 27 units (9 rows + 9 columns + 9 boxes)', () {
      expect(shape.units.length, 27);
      expect(shape.units.every((u) => u.cells.length == 9), isTrue);
    });

    test('every cell belongs to exactly 3 units', () {
      for (final cell in shape.activeCells) {
        expect(shape.unitsContaining(cell.$1, cell.$2), hasLength(3));
      }
    });

    test('row 0 unit contains all 9 cells of that row', () {
      final row0 = shape.unitsContaining(0, 0).firstWhere((u) => u.kind == UnitKind.row);
      expect(row0.cells.toSet(), {for (var c = 0; c < 9; c++) (0, c)});
    });
  });

  group('PuzzleShape.samurai', () {
    final shape = PuzzleShape.samurai;

    test('has a 21x21 bounding box with 369 active cells', () {
      expect(shape.height, 21);
      expect(shape.width, 21);
      expect(shape.activeCells.length, 369);
    });

    test('has 131 units (5 grids x 27, minus 4 duplicate shared boxes)', () {
      expect(shape.units.length, 131);
      expect(shape.units.every((u) => u.cells.length == 9), isTrue);
    });

    test('an ordinary (non-shared) cell belongs to exactly 3 units', () {
      // (0, 0) is only ever part of the top-left grid.
      expect(shape.unitsContaining(0, 0), hasLength(3));
    });

    test('a shared-box cell belongs to 5 units: two rows, two columns, one box', () {
      // (7, 7) sits in the box shared between the top-left and center grids.
      final units = shape.unitsContaining(7, 7);
      expect(units, hasLength(5));
      expect(units.where((u) => u.kind == UnitKind.row), hasLength(2));
      expect(units.where((u) => u.kind == UnitKind.column), hasLength(2));
      expect(units.where((u) => u.kind == UnitKind.box), hasLength(1));
    });

    test('the shared box unit is the same 9 cells for both grids it belongs to', () {
      final boxUnits = shape.unitsContaining(7, 7).where((u) => u.kind == UnitKind.box);
      expect(boxUnits, hasLength(1));
      expect(boxUnits.first.cells.toSet(), {
        for (var r = 6; r <= 8; r++) for (var c = 6; c <= 8; c++) (r, c),
      });
    });

    test('the gap between the top-left and top-right grids is inactive', () {
      expect(shape.activeCells.contains((0, 9)), isFalse);
      expect(shape.activeCells.contains((0, 10)), isFalse);
      expect(shape.activeCells.contains((0, 11)), isFalse);
    });

    test('the top-left grid row 6 and center grid row 0 are distinct, overlapping units', () {
      // Global row 6 hosts two separate 9-cell row constraints, not one.
      // (6, 0) is only in the top-left grid; (6, 10) is only in the center
      // grid (both outside the box the two grids share), so each resolves
      // unambiguously to one grid's own row unit.
      final topLeftRow = shape.unitsContaining(6, 0).firstWhere((u) => u.kind == UnitKind.row);
      final centerRow = shape.unitsContaining(6, 10).firstWhere((u) => u.kind == UnitKind.row);
      expect(topLeftRow.cells.toSet(), isNot(centerRow.cells.toSet()));
      expect(
        topLeftRow.cells.toSet().intersection(centerRow.cells.toSet()),
        {(6, 6), (6, 7), (6, 8)},
      );
    });
  });

  group('PuzzleShape.twin', () {
    final shape = PuzzleShape.twin;

    test('has a 15x15 bounding box with 153 active cells', () {
      expect(shape.height, 15);
      expect(shape.width, 15);
      expect(shape.activeCells.length, 153);
    });

    test('has 53 units (2 grids x 27, minus 1 duplicate shared box)', () {
      expect(shape.units.length, 53);
      expect(shape.units.every((u) => u.cells.length == 9), isTrue);
    });

    test('an ordinary (non-shared) cell belongs to exactly 3 units', () {
      expect(shape.unitsContaining(0, 0), hasLength(3));
    });

    test('the shared-box cell belongs to 5 units: two rows, two columns, one box', () {
      // (7, 7) sits in the box shared between the two grids.
      final units = shape.unitsContaining(7, 7);
      expect(units, hasLength(5));
      expect(units.where((u) => u.kind == UnitKind.row), hasLength(2));
      expect(units.where((u) => u.kind == UnitKind.column), hasLength(2));
      expect(units.where((u) => u.kind == UnitKind.box), hasLength(1));
      expect(units.firstWhere((u) => u.kind == UnitKind.box).cells.toSet(), {
        for (var r = 6; r <= 8; r++) for (var c = 6; c <= 8; c++) (r, c),
      });
    });
  });

  group('PuzzleShape.gattai8', () {
    final shape = PuzzleShape.gattai8;

    test('has a 21x33 bounding box with 576 active cells', () {
      expect(shape.height, 21);
      expect(shape.width, 33);
      expect(shape.activeCells.length, 576);
    });

    test('has 208 units (8 grids x 27, minus 8 duplicate shared boxes)', () {
      expect(shape.units.length, 208);
      expect(shape.units.every((u) => u.cells.length == 9), isTrue);
    });

    test('an ordinary (non-shared) cell belongs to exactly 3 units', () {
      expect(shape.unitsContaining(0, 0), hasLength(3));
    });

    test('the top-left grid shares a box with the first middle-row grid', () {
      // (7, 7) sits in the box shared between the top-left grid (origin
      // 0,0) and the first middle-row grid (origin 6,6).
      final units = shape.unitsContaining(7, 7);
      expect(units, hasLength(5));
      expect(units.firstWhere((u) => u.kind == UnitKind.box).cells.toSet(), {
        for (var r = 6; r <= 8; r++) for (var c = 6; c <= 8; c++) (r, c),
      });
    });

    test('the gap between the two middle-row grids is inactive', () {
      // The middle-row grids span cols 6-14 and 18-26; col 15-17 at a
      // middle-only row (e.g. row 10) falls between them.
      expect(shape.activeCells.contains((10, 15)), isFalse);
      expect(shape.activeCells.contains((10, 16)), isFalse);
      expect(shape.activeCells.contains((10, 17)), isFalse);
    });
  });

  group('PuzzleShape.sohei', () {
    final shape = PuzzleShape.sohei;

    test('has a 21x21 bounding box with 288 active cells', () {
      expect(shape.height, 21);
      expect(shape.width, 21);
      expect(shape.activeCells.length, 288);
    });

    test('has 104 units (4 grids x 27, minus 4 duplicate shared boxes)', () {
      expect(shape.units.length, 104);
      expect(shape.units.every((u) => u.cells.length == 9), isTrue);
    });

    test('an ordinary (non-shared) cell belongs to exactly 3 units', () {
      expect(shape.unitsContaining(0, 6), hasLength(3));
    });

    test('the top and left grids share a box', () {
      // (7, 7) sits in the box shared between the top grid (origin 0,6)
      // and the left grid (origin 6,0).
      final units = shape.unitsContaining(7, 7);
      expect(units, hasLength(5));
      expect(units.firstWhere((u) => u.kind == UnitKind.box).cells.toSet(), {
        for (var r = 6; r <= 8; r++) for (var c = 6; c <= 8; c++) (r, c),
      });
    });

    test('the center hole is inactive - unlike Samurai, no 5th grid fills it', () {
      expect(shape.activeCells.contains((10, 10)), isFalse);
    });

    test('the top and bottom grids do not overlap - only ring-adjacent grids do', () {
      // Top spans rows 0-8; bottom spans rows 12-20 - no shared box.
      final topUnits = shape.unitsContaining(0, 10);
      final bottomUnits = shape.unitsContaining(20, 10);
      final topBox = topUnits.firstWhere((u) => u.kind == UnitKind.box).cells.toSet();
      final bottomBox = bottomUnits.firstWhere((u) => u.kind == UnitKind.box).cells.toSet();
      expect(topBox.intersection(bottomBox), isEmpty);
    });
  });
}
