import '../models/board.dart';
import 'candidates.dart';

/// Solving techniques ranked roughly by required skill. The rank (enum
/// index) lines up with [Difficulty.maxAllowedTechniqueRank]: a puzzle
/// solvable start-to-finish with rank-0 steps only is "Easy", one that also
/// needs rank-1 steps is "Medium", and so on.
enum SolvingTechnique { nakedSingle, hiddenSingle, pairElimination, backtracking }

extension SolvingTechniqueX on SolvingTechnique {
  int get rank => index;

  String get label {
    switch (this) {
      case SolvingTechnique.nakedSingle:
        return 'Naked Single';
      case SolvingTechnique.hiddenSingle:
        return 'Hidden Single';
      case SolvingTechnique.pairElimination:
        return 'Paar-Ausschluss (Naked Pair / Pointing Pair)';
      case SolvingTechnique.backtracking:
        return 'Rückwärtssuche (Ausprobieren)';
    }
  }
}

/// One logically derived step: place [value] at (row, col) because of
/// [technique], with a short human-readable [explanation] for the hint UI.
class HintStep {
  final int row;
  final int col;
  final int value;
  final SolvingTechnique technique;
  final String explanation;

  const HintStep({
    required this.row,
    required this.col,
    required this.value,
    required this.technique,
    required this.explanation,
  });
}

/// Logical (non-brute-force) solving engine. Powers both the in-game hint
/// button ("show the next logically derivable number") and the difficulty
/// rating used by the puzzle generator.
class HintEngine {
  const HintEngine._();

  /// Finds the next cell whose value follows from pure logic, trying
  /// increasingly advanced techniques. Returns `null` if none of the
  /// implemented techniques apply (a brute-force guess would be needed).
  static HintStep? nextLogicalStep(Board board) {
    final naked = _findNakedSingle(board);
    if (naked != null) return naked;

    final hidden = _findHiddenSingle(board);
    if (hidden != null) return hidden;

    // Pair-based elimination narrows candidates without directly placing a
    // value; retry the simple techniques afterwards with the refined set.
    final refined = _applyEliminationTechniques(board);
    if (refined != null) {
      final nakedAfter = _findNakedSingle(board, candidates: refined);
      if (nakedAfter != null) return nakedAfter;
      final hiddenAfter = _findHiddenSingle(board, candidates: refined);
      if (hiddenAfter != null) return hiddenAfter;
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
            explanation: 'Zeile ${r + 1}, Spalte ${c + 1} hat nur einen möglichen Kandidaten: '
                '${options.first}.',
          );
        }
      }
    }
    return null;
  }

  static HintStep? _findHiddenSingle(Board board, {List<List<Set<int>>>? candidates}) {
    final cands = candidates ?? Candidates.forBoard(board);

    HintStep? searchUnit(List<List<int>> unit, String unitLabel) {
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
            explanation: 'In $unitLabel kann die $value nur noch in Zeile ${r + 1}, '
                'Spalte ${c + 1} stehen.',
          );
        }
      }
      return null;
    }

    for (var r = 0; r < kBoardSize; r++) {
      final result = searchUnit([for (var c = 0; c < kBoardSize; c++) [r, c]], 'Zeile ${r + 1}');
      if (result != null) return result;
    }
    for (var c = 0; c < kBoardSize; c++) {
      final result = searchUnit([for (var r = 0; r < kBoardSize; r++) [r, c]], 'Spalte ${c + 1}');
      if (result != null) return result;
    }
    for (var br = 0; br < kBoxSize; br++) {
      for (var bc = 0; bc < kBoxSize; bc++) {
        final unit = [
          for (var r = br * kBoxSize; r < br * kBoxSize + kBoxSize; r++)
            for (var c = bc * kBoxSize; c < bc * kBoxSize + kBoxSize; c++) [r, c],
        ];
        final result = searchUnit(unit, 'Box ${br * kBoxSize + bc + 1}');
        if (result != null) return result;
      }
    }
    return null;
  }

  /// Applies naked-pair and pointing-pair elimination across every unit on
  /// a working copy of the candidate grid. Returns the refined candidates
  /// if at least one elimination happened, else `null`.
  static List<List<Set<int>>>? _applyEliminationTechniques(Board board) {
    final cands = Candidates.forBoard(board);
    var changed = false;

    final units = <List<List<int>>>[
      for (var r = 0; r < kBoardSize; r++) [for (var c = 0; c < kBoardSize; c++) [r, c]],
      for (var c = 0; c < kBoardSize; c++) [for (var r = 0; r < kBoardSize; r++) [r, c]],
      for (var br = 0; br < kBoxSize; br++)
        for (var bc = 0; bc < kBoxSize; bc++)
          [
            for (var r = br * kBoxSize; r < br * kBoxSize + kBoxSize; r++)
              for (var c = bc * kBoxSize; c < bc * kBoxSize + kBoxSize; c++) [r, c],
          ],
    ];

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
        final boxCells = [
          for (var r = br * kBoxSize; r < br * kBoxSize + kBoxSize; r++)
            for (var c = bc * kBoxSize; c < bc * kBoxSize + kBoxSize; c++) [r, c],
        ];
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

    return changed ? cands : null;
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
