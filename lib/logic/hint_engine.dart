import '../models/board.dart';
import '../models/puzzle_shape.dart';
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
  xyWing,
  swordfish,
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
///
/// Shape-agnostic: every technique reads its units from `board.shape.units`
/// (see `PuzzleShape`) instead of assuming a fixed 9x9 grid, so the same
/// code serves a classic board and a multi-grid layout like Samurai. Naked
/// singles, hidden singles, naked pairs/triples and hidden pairs are purely
/// per-unit checks and so are automatically correct even for a Samurai
/// shared-box cell (which simply belongs to more units - 5 instead of 3).
/// X-Wing and Swordfish are inherently a single grid's own row/column
/// system (see [Unit.gridId]) and are applied per constituent grid, since
/// two different grids' columns can share a global column number without
/// being the same constraint.
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
    SolvingTechnique.xyWing,
    SolvingTechnique.swordfish,
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
    final units = board.shape.units;

    for (final tier in _eliminationTiers) {
      final changed = switch (tier) {
        SolvingTechnique.pairElimination => _applyPairElimination(board, cands, units),
        SolvingTechnique.hiddenPair => _applyHiddenPairs(board, cands, units),
        SolvingTechnique.nakedTriple => _applyNakedTriples(board, cands, units),
        SolvingTechnique.xWing => _applyXWing(board, cands, units),
        SolvingTechnique.xyWing => _applyXYWing(board, cands),
        SolvingTechnique.swordfish => _applySwordfish(board, cands, units),
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
    for (final (r, c) in board.shape.activeCells) {
      if (!board.cellAt(r, c).isEmpty) continue;
      final options = cands[r][c];
      if (options.length == 1) {
        return HintStep(row: r, col: c, value: options.first, technique: SolvingTechnique.nakedSingle);
      }
    }
    return null;
  }

  static HintStep? _findHiddenSingle(Board board, {List<List<Set<int>>>? candidates}) {
    final cands = candidates ?? Candidates.forBoard(board);
    final unitType = {
      UnitKind.row: HintUnitType.row,
      UnitKind.column: HintUnitType.column,
      UnitKind.box: HintUnitType.box,
    };

    for (final unit in board.shape.units) {
      for (var value = 1; value <= kBoardSize; value++) {
        final cellsWithValue = unit.cells
            .where((pos) => board.cellAt(pos.$1, pos.$2).isEmpty && cands[pos.$1][pos.$2].contains(value))
            .toList();
        if (cellsWithValue.length == 1) {
          final (r, c) = cellsWithValue.first;
          return HintStep(
            row: r,
            col: c,
            value: value,
            technique: SolvingTechnique.hiddenSingle,
            singleKind: SingleKind.hidden,
            hiddenUnit: unitType[unit.kind],
          );
        }
      }
    }
    return null;
  }

  /// Naked pairs (two cells in a unit sharing exactly the same 2
  /// candidates), plus the generalized pointing-pair / box-line-reduction
  /// rule: whenever two *different* units share at least 2 cells (in a
  /// classic board this is always one box and one of its own rows/columns;
  /// in Samurai a shared box additionally links to the second grid's
  /// row/column units through that same box) and a value's candidates
  /// within one of the units all fall inside the shared cells, that value
  /// can be removed from the other unit's remaining cells.
  static bool _applyPairElimination(Board board, List<List<Set<int>>> cands, List<Unit> units) {
    var changed = false;

    for (final unit in units) {
      final emptyCells = unit.cells.where((pos) => board.cellAt(pos.$1, pos.$2).isEmpty).toList();
      for (var i = 0; i < emptyCells.length; i++) {
        final (r1, c1) = emptyCells[i];
        if (cands[r1][c1].length != 2) continue;
        for (var j = i + 1; j < emptyCells.length; j++) {
          final (r2, c2) = emptyCells[j];
          if (cands[r2][c2].length != 2) continue;
          if (!_setEquals(cands[r1][c1], cands[r2][c2])) continue;
          final pairValues = cands[r1][c1];
          for (final pos in emptyCells) {
            if (pos == (r1, c1) || pos == (r2, c2)) continue;
            final before = cands[pos.$1][pos.$2].length;
            cands[pos.$1][pos.$2].removeAll(pairValues);
            if (cands[pos.$1][pos.$2].length != before) changed = true;
          }
        }
      }
    }

    for (final (unitA, unitB) in board.shape.linkedUnitPairs) {
      final sharedCells = unitA.cells.toSet().intersection(unitB.cells.toSet());

      for (var value = 1; value <= kBoardSize; value++) {
        final aCellsWithValue = unitA.cells
            .where((pos) => board.cellAt(pos.$1, pos.$2).isEmpty && cands[pos.$1][pos.$2].contains(value));
        if (aCellsWithValue.isEmpty) continue;
        if (!aCellsWithValue.every(sharedCells.contains)) continue;

        for (final pos in unitB.cells) {
          if (sharedCells.contains(pos)) continue;
          if (board.cellAt(pos.$1, pos.$2).isEmpty && cands[pos.$1][pos.$2].remove(value)) changed = true;
        }
      }
    }

    return changed;
  }

  /// Hidden pairs: two values in a unit are only ever candidates in the same
  /// two cells -> every other candidate can be stripped from those cells.
  static bool _applyHiddenPairs(Board board, List<List<Set<int>>> cands, List<Unit> units) {
    var changed = false;
    for (final unit in units) {
      final emptyCells = unit.cells.where((pos) => board.cellAt(pos.$1, pos.$2).isEmpty).toList();
      for (var v1 = 1; v1 <= kBoardSize; v1++) {
        final cellsV1 = emptyCells.where((p) => cands[p.$1][p.$2].contains(v1)).toList();
        if (cellsV1.length != 2) continue;
        for (var v2 = v1 + 1; v2 <= kBoardSize; v2++) {
          final cellsV2 = emptyCells.where((p) => cands[p.$1][p.$2].contains(v2)).toList();
          if (cellsV2.length != 2 || !_samePositions(cellsV1, cellsV2)) continue;
          for (final pos in cellsV1) {
            final before = cands[pos.$1][pos.$2].length;
            cands[pos.$1][pos.$2].removeWhere((v) => v != v1 && v != v2);
            if (cands[pos.$1][pos.$2].length != before) changed = true;
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
  static bool _applyNakedTriples(Board board, List<List<Set<int>>> cands, List<Unit> units) {
    var changed = false;
    for (final unit in units) {
      final emptyCells = unit.cells.where((pos) => board.cellAt(pos.$1, pos.$2).isEmpty).toList();
      final candidateCells = emptyCells.where((p) {
        final len = cands[p.$1][p.$2].length;
        return len == 2 || len == 3;
      }).toList();

      for (var i = 0; i < candidateCells.length; i++) {
        for (var j = i + 1; j < candidateCells.length; j++) {
          for (var k = j + 1; k < candidateCells.length; k++) {
            final a = candidateCells[i], b = candidateCells[j], c = candidateCells[k];
            final union = <int>{...cands[a.$1][a.$2], ...cands[b.$1][b.$2], ...cands[c.$1][c.$2]};
            if (union.length != 3) continue;
            for (final pos in emptyCells) {
              if (pos == a || pos == b || pos == c) continue;
              final before = cands[pos.$1][pos.$2].length;
              cands[pos.$1][pos.$2].removeAll(union);
              if (cands[pos.$1][pos.$2].length != before) changed = true;
            }
          }
        }
      }
    }
    return changed;
  }

  /// X-Wing: if a value's candidates in two rows (of the *same* grid - see
  /// [Unit.gridId]) are confined to the same two columns, that value can be
  /// removed from the rest of those columns in every other row of that
  /// grid (and symmetrically for two columns confining a value to the same
  /// two rows).
  static bool _applyXWing(Board board, List<List<Set<int>>> cands, List<Unit> units) {
    var changed = false;
    for (final gridId in _gridIds(units)) {
      final rows = units.where((u) => u.kind == UnitKind.row && u.gridId == gridId).toList();
      final cols = units.where((u) => u.kind == UnitKind.column && u.gridId == gridId).toList();
      changed |= _applyFishForGrid(board, cands, primary: rows, secondary: cols, size: 2);
      changed |= _applyFishForGrid(board, cands, primary: cols, secondary: rows, size: 2);
    }
    return changed;
  }

  /// Swordfish: the X-Wing pattern generalized to three rows (or columns)
  /// of the same grid - if a value's candidates across three rows are
  /// confined to the same three columns overall, that value can be removed
  /// from the rest of those columns (and symmetrically for columns).
  static bool _applySwordfish(Board board, List<List<Set<int>>> cands, List<Unit> units) {
    var changed = false;
    for (final gridId in _gridIds(units)) {
      final rows = units.where((u) => u.kind == UnitKind.row && u.gridId == gridId).toList();
      final cols = units.where((u) => u.kind == UnitKind.column && u.gridId == gridId).toList();
      changed |= _applyFishForGrid(board, cands, primary: rows, secondary: cols, size: 3);
      changed |= _applyFishForGrid(board, cands, primary: cols, secondary: rows, size: 3);
    }
    return changed;
  }

  static Set<int> _gridIds(List<Unit> units) => {for (final u in units) u.gridId};

  /// Shared X-Wing (size 2) / Swordfish (size 3) engine: for each value,
  /// finds [size] units in [primary] whose candidate cells for that value
  /// fall within the same [size] units of [secondary] overall, then removes
  /// the value from those [secondary] units' cells outside [primary].
  static bool _applyFishForGrid(
    Board board,
    List<List<Set<int>>> cands, {
    required List<Unit> primary,
    required List<Unit> secondary,
    required int size,
  }) {
    var changed = false;
    for (var value = 1; value <= kBoardSize; value++) {
      final candidatesByPrimary = <Unit, Set<Unit>>{};
      for (final p in primary) {
        final secondaryHits = <Unit>{};
        for (final pos in p.cells) {
          if (!board.cellAt(pos.$1, pos.$2).isEmpty || !cands[pos.$1][pos.$2].contains(value)) continue;
          for (final s in secondary) {
            if (s.cells.contains(pos)) secondaryHits.add(s);
          }
        }
        if (secondaryHits.length >= 2 && secondaryHits.length <= size) {
          candidatesByPrimary[p] = secondaryHits;
        }
      }

      final withCandidates = candidatesByPrimary.keys.toList();
      void tryCombo(List<Unit> chosen, int start) {
        if (chosen.length == size) {
          final union = <Unit>{};
          for (final p in chosen) {
            union.addAll(candidatesByPrimary[p]!);
          }
          if (union.length != size) return;
          for (final s in union) {
            for (final pos in s.cells) {
              if (chosen.any((p) => p.cells.contains(pos))) continue;
              if (board.cellAt(pos.$1, pos.$2).isEmpty && cands[pos.$1][pos.$2].remove(value)) changed = true;
            }
          }
          return;
        }
        for (var i = start; i < withCandidates.length; i++) {
          tryCombo([...chosen, withCandidates[i]], i + 1);
        }
      }

      tryCombo(const [], 0);
    }
    return changed;
  }

  /// XY-Wing: a bi-value "pivot" cell with candidates {a, b} sees two other
  /// bi-value "pincer" cells {a, c} and {b, c} (c shared, distinct from a and
  /// b). Whichever pincer doesn't match the pivot's actual value still forces
  /// c into the other pincer, so c can be removed from every cell that sees
  /// both pincers (the pivot itself never holds c, so it's left alone).
  static bool _applyXYWing(Board board, List<List<Set<int>>> cands) {
    var changed = false;
    final biValueCells = [
      for (final (r, c) in board.shape.activeCells)
        if (board.cellAt(r, c).isEmpty && cands[r][c].length == 2) (r, c),
    ];

    for (final pivot in biValueCells) {
      // biValueCells is a snapshot taken before this loop started, but the
      // eliminations below mutate `cands` in place as we go - a cell that
      // was bi-value at snapshot time may have since dropped to one (or
      // zero) candidates, so its live state must be re-checked before use.
      if (cands[pivot.$1][pivot.$2].length != 2) continue;
      final pivotCands = cands[pivot.$1][pivot.$2].toList();
      final a = pivotCands[0], b = pivotCands[1];
      final peers = biValueCells.where((p) => _sees(board, pivot, p)).toList();

      for (final x in peers) {
        final xc = cands[x.$1][x.$2];
        if (xc.length != 2 || !xc.contains(a) || xc.contains(b)) continue;
        final c = xc.firstWhere((v) => v != a);

        for (final y in peers) {
          if (y == x) continue;
          final yc = cands[y.$1][y.$2];
          if (yc.length != 2 || !yc.contains(b) || yc.contains(a) || !yc.contains(c)) continue;

          for (final pos in board.shape.activeCells) {
            if (pos == x || pos == y) continue;
            if (!board.cellAt(pos.$1, pos.$2).isEmpty) continue;
            if (_sees(board, x, pos) && _sees(board, y, pos) && cands[pos.$1][pos.$2].remove(c)) {
              changed = true;
            }
          }
        }
      }
    }
    return changed;
  }

  /// Whether two distinct cells share any unit (row, column or box) - i.e.
  /// placing a value in one rules it out in the other. At a Samurai
  /// shared-box cell this naturally spans both grids it belongs to, since
  /// that cell's units already include both grids' row/column/box units.
  static bool _sees(Board board, (int, int) a, (int, int) b) {
    if (a == b) return false;
    return board.unitsContaining(a.$1, a.$2).any((u) => u.cells.contains(b));
  }

  static bool _samePositions(List<(int, int)> a, List<(int, int)> b) {
    if (a.length != b.length) return false;
    return a.every(b.contains);
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
