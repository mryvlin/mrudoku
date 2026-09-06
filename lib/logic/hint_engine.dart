import '../models/board.dart';
import 'candidates.dart';

/// Solving techniques ranked roughly by required skill. The rank (enum
/// index) lines up with [Difficulty.maxAllowedTechniqueRank]: a puzzle
/// solvable start-to-finish with rank-0 steps only is "Easy", one that also
/// needs rank-1 steps is "Medium", and so on.
enum SolvingTechnique {
  nakedSingle,
  hiddenSingle,
  pairElimination,
  hiddenPair,
  nakedTriple,
  xWing,
  backtracking,
}

extension SolvingTechniqueX on SolvingTechnique {
  int get rank => index;
}

/// Which base rule actually placed the value - even when [HintStep.technique]
/// reports an elimination tier (e.g. [SolvingTechnique.pairElimination]),
/// the value is always placed by a naked or hidden single once that tier has
/// narrowed the candidates down enough.
enum SingleKind { naked, hidden }

/// The unit type (row, column or box) whose analysis revealed a hidden
/// single - only meaningful when [HintStep.singleKind] is
/// [SingleKind.hidden]. The UI uses this together with [HintStep.row]/`col`
/// to name the unit (its 1-based index is fully derivable from row/col).
enum HintUnitType { row, column, box }

/// One logically derived step: place [value] at (row, col) because of
/// [technique]. This is deliberately just structured data with no
/// human-readable text - see `ui/hint_text.dart` for the localized
/// explanation, since text/localization doesn't belong in this pure-Dart
/// logic layer.
class HintStep {
  final int row;
  final int col;
  final int value;
  final SolvingTechnique technique;
  final SingleKind singleKind;
  final HintUnitType? hiddenUnit;

  const HintStep({
    required this.row,
    required this.col,
    required this.value,
    required this.technique,
    this.singleKind = SingleKind.naked,
    this.hiddenUnit,
  }) : assert(
          (singleKind == SingleKind.hidden) == (hiddenUnit != null),
          'hiddenUnit must be set if and only if singleKind is hidden - '
          'ui/hint_text.dart force-unwraps it whenever singleKind is hidden',
        );
}

/// Logical (non-brute-force) solving engine. Powers both the in-game hint
/// button ("show the next logically derivable number") and the difficulty
/// rating used by the puzzle generator.
class HintEngine {
  const HintEngine._();

  /// Techniques tried, in increasing order of difficulty, when a plain
  /// naked/hidden single isn't directly available. Each one only narrows
  /// candidates down (it never places a value by itself); after each tier
  /// runs, we retry the simple single-finders with the refined candidates.
  static const List<SolvingTechnique> _eliminationTiers = [
    SolvingTechnique.pairElimination,
    SolvingTechnique.hiddenPair,
    SolvingTechnique.nakedTriple,
    SolvingTechnique.xWing,
  ];

  /// Finds the next cell whose value follows from pure logic, trying
  /// increasingly advanced techniques. Returns `null` if none of the
  /// implemented techniques apply (a brute-force guess would be needed).
  static HintStep? nextLogicalStep(Board board) {
    final naked = _findNakedSingle(board);
    if (naked != null) return naked;

    final hidden = _findHiddenSingle(board);
    if (hidden != null) return hidden;

    // Elimination tiers share one working candidate grid: eliminations from
    // an easier tier stay in effect while a harder tier is attempted, just
    // like a human solver would keep earlier deductions around.
    final cands = Candidates.forBoard(board);
    final units = _buildUnits();

    for (final tier in _eliminationTiers) {
      final changed = switch (tier) {
        SolvingTechnique.pairElimination => _applyPairElimination(board, cands, units),
        SolvingTechnique.hiddenPair => _applyHiddenPairs(board, cands, units),
        SolvingTechnique.nakedTriple => _applyNakedTriples(board, cands, units),
        SolvingTechnique.xWing => _applyXWing(board, cands),
        _ => false,
      };
      if (!changed) continue;

      final nakedAfter = _findNakedSingle(board, candidates: cands);
      if (nakedAfter != null) {
        return HintStep(
          row: nakedAfter.row,
          col: nakedAfter.col,
          value: nakedAfter.value,
          technique: tier,
        );
      }
      final hiddenAfter = _findHiddenSingle(board, candidates: cands);
      if (hiddenAfter != null) {
        return HintStep(
          row: hiddenAfter.row,
          col: hiddenAfter.col,
          value: hiddenAfter.value,
          technique: tier,
          singleKind: SingleKind.hidden,
          hiddenUnit: hiddenAfter.hiddenUnit,
        );
      }
    }

    return null;
  }

  static HintStep? _findNakedSingle(Board board, {List<List<Set<int>>>? candidates}) {
    final cands = candidates ?? Candidates.forBoard(board);
    for (var r = 0; r < kBoardSize; r++) {
      for (var c = 0; c < kBoardSize; c++) {
        if (!board.cellAt(r, c).isEmpty) continue;
        final options = cands[r][c];
        if (options.length == 1) {
          return HintStep(
            row: r,
            col: c,
            value: options.first,
            technique: SolvingTechnique.nakedSingle,
          );
        }
      }
    }
    return null;
  }

  static HintStep? _findHiddenSingle(Board board, {List<List<Set<int>>>? candidates}) {
    final cands = candidates ?? Candidates.forBoard(board);

    HintStep? searchUnit(List<List<int>> unit, HintUnitType unitType) {
      for (var value = 1; value <= kBoardSize; value++) {
        final cellsWithValue = unit
            .where((pos) => board.cellAt(pos[0], pos[1]).isEmpty && cands[pos[0]][pos[1]].contains(value))
            .toList();
        if (cellsWithValue.length == 1) {
          final r = cellsWithValue.first[0], c = cellsWithValue.first[1];
          return HintStep(
            row: r,
            col: c,
            value: value,
            technique: SolvingTechnique.hiddenSingle,
            singleKind: SingleKind.hidden,
            hiddenUnit: unitType,
          );
        }
      }
      return null;
    }

    for (var r = 0; r < kBoardSize; r++) {
      final result = searchUnit([for (var c = 0; c < kBoardSize; c++) [r, c]], HintUnitType.row);
      if (result != null) return result;
    }
    for (var c = 0; c < kBoardSize; c++) {
      final result = searchUnit([for (var r = 0; r < kBoardSize; r++) [r, c]], HintUnitType.column);
      if (result != null) return result;
    }
    for (var br = 0; br < kBoxSize; br++) {
      for (var bc = 0; bc < kBoxSize; bc++) {
        final result = searchUnit(_boxPositions(br, bc), HintUnitType.box);
        if (result != null) return result;
      }
    }
    return null;
  }

  static List<List<List<int>>> _buildUnits() => [
        for (var r = 0; r < kBoardSize; r++) [for (var c = 0; c < kBoardSize; c++) [r, c]],
        for (var c = 0; c < kBoardSize; c++) [for (var r = 0; r < kBoardSize; r++) [r, c]],
        for (var br = 0; br < kBoxSize; br++)
          for (var bc = 0; bc < kBoxSize; bc++) _boxPositions(br, bc),
      ];

  static List<List<int>> _boxPositions(int boxRow, int boxCol) => [
        for (var r = boxRow * kBoxSize; r < boxRow * kBoxSize + kBoxSize; r++)
          for (var c = boxCol * kBoxSize; c < boxCol * kBoxSize + kBoxSize; c++) [r, c],
      ];

  /// Naked pairs, pointing pairs and box-line reduction (claiming) across
  /// every unit on a working copy of the candidate grid. Mutates [cands] in
  /// place and returns whether anything was eliminated.
  static bool _applyPairElimination(
    Board board,
    List<List<Set<int>>> cands,
    List<List<List<int>>> units,
  ) {
    var changed = false;

    // Naked pairs: two cells in a unit share exactly the same 2 candidates
    // -> those two values can be removed from every other cell in the unit.
    for (final unit in units) {
      final emptyCells = unit.where((pos) => board.cellAt(pos[0], pos[1]).isEmpty).toList();
      for (var i = 0; i < emptyCells.length; i++) {
        final r1 = emptyCells[i][0], c1 = emptyCells[i][1];
        if (cands[r1][c1].length != 2) continue;
        for (var j = i + 1; j < emptyCells.length; j++) {
          final r2 = emptyCells[j][0], c2 = emptyCells[j][1];
          if (cands[r2][c2].length != 2) continue;
          if (!_setEquals(cands[r1][c1], cands[r2][c2])) continue;
          final pairValues = cands[r1][c1];
          for (final pos in emptyCells) {
            if ((pos[0] == r1 && pos[1] == c1) || (pos[0] == r2 && pos[1] == c2)) continue;
            final before = cands[pos[0]][pos[1]].length;
            cands[pos[0]][pos[1]].removeAll(pairValues);
            if (cands[pos[0]][pos[1]].length != before) changed = true;
          }
        }
      }
    }

    // Pointing pairs: if every candidate for a value within a box lies in a
    // single row or column, that value can be removed from the rest of that
    // row/column outside the box.
    for (var br = 0; br < kBoxSize; br++) {
      for (var bc = 0; bc < kBoxSize; bc++) {
        final boxCells = _boxPositions(br, bc);
        for (var value = 1; value <= kBoardSize; value++) {
          final withValue = boxCells
              .where((pos) => board.cellAt(pos[0], pos[1]).isEmpty && cands[pos[0]][pos[1]].contains(value))
              .toList();
          if (withValue.length < 2) continue;
          final rows = withValue.map((p) => p[0]).toSet();
          final cols = withValue.map((p) => p[1]).toSet();
          if (rows.length == 1) {
            final row = rows.first;
            for (var c = 0; c < kBoardSize; c++) {
              if (c ~/ kBoxSize == bc) continue;
              if (board.cellAt(row, c).isEmpty && cands[row][c].remove(value)) changed = true;
            }
          } else if (cols.length == 1) {
            final col = cols.first;
            for (var r = 0; r < kBoardSize; r++) {
              if (r ~/ kBoxSize == br) continue;
              if (board.cellAt(r, col).isEmpty && cands[r][col].remove(value)) changed = true;
            }
          }
        }
      }
    }

    // Box-line reduction (claiming): the converse of pointing pairs - if
    // every candidate for a value within a row or column lies in a single
    // box, that value can be removed from the rest of that box.
    for (var r = 0; r < kBoardSize; r++) {
      for (var value = 1; value <= kBoardSize; value++) {
        final colsWithValue = [
          for (var c = 0; c < kBoardSize; c++)
            if (board.cellAt(r, c).isEmpty && cands[r][c].contains(value)) c,
        ];
        if (colsWithValue.length < 2) continue;
        final boxCols = colsWithValue.map((c) => c ~/ kBoxSize).toSet();
        if (boxCols.length != 1) continue;
        final boxRow = r ~/ kBoxSize, boxCol = boxCols.first;
        for (final pos in _boxPositions(boxRow, boxCol)) {
          if (pos[0] == r) continue;
          if (board.cellAt(pos[0], pos[1]).isEmpty && cands[pos[0]][pos[1]].remove(value)) changed = true;
        }
      }
    }
    for (var c = 0; c < kBoardSize; c++) {
      for (var value = 1; value <= kBoardSize; value++) {
        final rowsWithValue = [
          for (var r = 0; r < kBoardSize; r++)
            if (board.cellAt(r, c).isEmpty && cands[r][c].contains(value)) r,
        ];
        if (rowsWithValue.length < 2) continue;
        final boxRows = rowsWithValue.map((r) => r ~/ kBoxSize).toSet();
        if (boxRows.length != 1) continue;
        final boxRow = boxRows.first, boxCol = c ~/ kBoxSize;
        for (final pos in _boxPositions(boxRow, boxCol)) {
          if (pos[1] == c) continue;
          if (board.cellAt(pos[0], pos[1]).isEmpty && cands[pos[0]][pos[1]].remove(value)) changed = true;
        }
      }
    }

    return changed;
  }

  /// Hidden pairs: two values in a unit are only ever candidates in the same
  /// two cells -> every other candidate can be stripped from those cells.
  static bool _applyHiddenPairs(
    Board board,
    List<List<Set<int>>> cands,
    List<List<List<int>>> units,
  ) {
    var changed = false;
    for (final unit in units) {
      final emptyCells = unit.where((pos) => board.cellAt(pos[0], pos[1]).isEmpty).toList();
      for (var v1 = 1; v1 <= kBoardSize; v1++) {
        final cellsV1 = emptyCells.where((p) => cands[p[0]][p[1]].contains(v1)).toList();
        if (cellsV1.length != 2) continue;
        for (var v2 = v1 + 1; v2 <= kBoardSize; v2++) {
          final cellsV2 = emptyCells.where((p) => cands[p[0]][p[1]].contains(v2)).toList();
          if (cellsV2.length != 2 || !_samePositions(cellsV1, cellsV2)) continue;
          for (final pos in cellsV1) {
            final before = cands[pos[0]][pos[1]].length;
            cands[pos[0]][pos[1]].removeWhere((v) => v != v1 && v != v2);
            if (cands[pos[0]][pos[1]].length != before) changed = true;
          }
        }
      }
    }
    return changed;
  }

  /// Naked triples: three cells in a unit whose combined candidates total
  /// exactly 3 values -> those values can be removed from every other cell
  /// in the unit (each of the three cells may itself hold only 2 or 3 of
  /// them, not necessarily all 3).
  static bool _applyNakedTriples(
    Board board,
    List<List<Set<int>>> cands,
    List<List<List<int>>> units,
  ) {
    var changed = false;
    for (final unit in units) {
      final emptyCells = unit.where((pos) => board.cellAt(pos[0], pos[1]).isEmpty).toList();
      final candidateCells = emptyCells.where((p) {
        final len = cands[p[0]][p[1]].length;
        return len == 2 || len == 3;
      }).toList();

      for (var i = 0; i < candidateCells.length; i++) {
        for (var j = i + 1; j < candidateCells.length; j++) {
          for (var k = j + 1; k < candidateCells.length; k++) {
            final a = candidateCells[i], b = candidateCells[j], c = candidateCells[k];
            final union = <int>{
              ...cands[a[0]][a[1]],
              ...cands[b[0]][b[1]],
              ...cands[c[0]][c[1]],
            };
            if (union.length != 3) continue;
            for (final pos in emptyCells) {
              final isMember = (pos[0] == a[0] && pos[1] == a[1]) ||
                  (pos[0] == b[0] && pos[1] == b[1]) ||
                  (pos[0] == c[0] && pos[1] == c[1]);
              if (isMember) continue;
              final before = cands[pos[0]][pos[1]].length;
              cands[pos[0]][pos[1]].removeAll(union);
              if (cands[pos[0]][pos[1]].length != before) changed = true;
            }
          }
        }
      }
    }
    return changed;
  }

  /// X-Wing: if a value's candidates in two rows are confined to the same
  /// two columns (or, symmetrically, two columns confine it to the same two
  /// rows), that value can be removed from the rest of those columns/rows.
  static bool _applyXWing(Board board, List<List<Set<int>>> cands) {
    var changed = false;
    for (var value = 1; value <= kBoardSize; value++) {
      final rowCols = <int, List<int>>{};
      for (var r = 0; r < kBoardSize; r++) {
        final cols = [
          for (var c = 0; c < kBoardSize; c++)
            if (board.cellAt(r, c).isEmpty && cands[r][c].contains(value)) c,
        ];
        if (cols.length == 2) rowCols[r] = cols;
      }
      final rowsWithPair = rowCols.keys.toList();
      for (var i = 0; i < rowsWithPair.length; i++) {
        for (var j = i + 1; j < rowsWithPair.length; j++) {
          final r1 = rowsWithPair[i], r2 = rowsWithPair[j];
          if (rowCols[r1]![0] != rowCols[r2]![0] || rowCols[r1]![1] != rowCols[r2]![1]) continue;
          final c1 = rowCols[r1]![0], c2 = rowCols[r1]![1];
          for (var r = 0; r < kBoardSize; r++) {
            if (r == r1 || r == r2) continue;
            for (final c in [c1, c2]) {
              if (board.cellAt(r, c).isEmpty && cands[r][c].remove(value)) changed = true;
            }
          }
        }
      }

      final colRows = <int, List<int>>{};
      for (var c = 0; c < kBoardSize; c++) {
        final rows = [
          for (var r = 0; r < kBoardSize; r++)
            if (board.cellAt(r, c).isEmpty && cands[r][c].contains(value)) r,
        ];
        if (rows.length == 2) colRows[c] = rows;
      }
      final colsWithPair = colRows.keys.toList();
      for (var i = 0; i < colsWithPair.length; i++) {
        for (var j = i + 1; j < colsWithPair.length; j++) {
          final c1 = colsWithPair[i], c2 = colsWithPair[j];
          if (colRows[c1]![0] != colRows[c2]![0] || colRows[c1]![1] != colRows[c2]![1]) continue;
          final r1 = colRows[c1]![0], r2 = colRows[c1]![1];
          for (var c = 0; c < kBoardSize; c++) {
            if (c == c1 || c == c2) continue;
            for (final r in [r1, r2]) {
              if (board.cellAt(r, c).isEmpty && cands[r][c].remove(value)) changed = true;
            }
          }
        }
      }
    }
    return changed;
  }

  static bool _samePositions(List<List<int>> a, List<List<int>> b) {
    if (a.length != b.length) return false;
    return a.every((pa) => b.any((pb) => pa[0] == pb[0] && pa[1] == pb[1]));
  }

  static bool _setEquals(Set<int> a, Set<int> b) => a.length == b.length && a.containsAll(b);

  /// Rates the hardest technique required to fully solve [board] using only
  /// logical steps. Returns [SolvingTechnique.backtracking] if the puzzle
  /// cannot be fully cleared this way (a guess would be required somewhere).
  static SolvingTechnique rateDifficulty(Board board) {
    var working = board.clone();
    var highest = SolvingTechnique.nakedSingle;

    while (!working.isFull) {
      final step = nextLogicalStep(working);
      if (step == null) return SolvingTechnique.backtracking;
      if (step.technique.rank > highest.rank) highest = step.technique;
      working = working.setCell(step.row, step.col, working.cellAt(step.row, step.col).copyWith(value: step.value));
    }
    return highest;
  }
}
