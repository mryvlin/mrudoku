import 'package:flutter/material.dart';

import '../../logic/hint_engine.dart';
import '../../models/board.dart';
import '../../models/puzzle_shape.dart';
import '../../models/settings.dart';
import '../highlight_colors.dart';
import 'sudoku_cell_widget.dart';

/// Renders [board]'s full grid - a plain 9x9 for the classic layout, or a
/// Samurai board's 21x21 bounding shape with its blank corner gaps - and
/// works out selection/peer/same-value/error highlighting and box-boundary
/// borders from [Board.shape] rather than a fixed grid size.
///
/// Stays square (or whatever aspect [PuzzleShape.height]/`width` implies -
/// 1:1 for both current shapes) and centered via [AspectRatio] so it scales
/// cleanly from a narrow phone in portrait mode up to a wide desktop
/// browser window.
class SudokuBoardWidget extends StatelessWidget {
  final Board board;
  final Board? solution;
  final int? selectedRow;
  final int? selectedCol;
  final bool highlightEnabled;
  final HighlightColor highlightColor;
  final bool showErrors;
  final void Function(int row, int col) onCellTap;

  /// When the last hint was a hidden single, the specific unit kind (row,
  /// column or box) whose analysis forced it - narrows peer highlighting
  /// down to just that unit instead of every unit the selected cell
  /// belongs to, so the player sees exactly which constraint did the work.
  /// `null` for every other technique, where every unit matters.
  final HintUnitType? hintFocusUnit;

  const SudokuBoardWidget({
    super.key,
    required this.board,
    required this.solution,
    required this.selectedRow,
    required this.selectedCol,
    required this.highlightEnabled,
    required this.highlightColor,
    required this.showErrors,
    required this.onCellTap,
    this.hintFocusUnit,
  });

  bool get _hasSelection => selectedRow != null && selectedCol != null;

  static bool _matchesFocus(UnitKind kind, HintUnitType focus) => switch (focus) {
        HintUnitType.row => kind == UnitKind.row,
        HintUnitType.column => kind == UnitKind.column,
        HintUnitType.box => kind == UnitKind.box,
      };

  /// A peer is any cell sharing at least one of the selected cell's units -
  /// on a classic board that's exactly "same row, column or box"; at a
  /// Samurai shared-box cell the selected cell has extra row/column units
  /// (one set per grid it belongs to), so its peers correctly span both
  /// grids without any special-casing here.
  bool _isPeer(int row, int col) {
    if (!_hasSelection) return false;
    final selectedUnits = board.unitsContaining(selectedRow!, selectedCol!);
    final focus = hintFocusUnit;
    final relevantUnits =
        focus == null ? selectedUnits : selectedUnits.where((u) => _matchesFocus(u.kind, focus));
    return relevantUnits.any((u) => u.cells.contains((row, col)));
  }

  /// A thick line belongs at global coordinate [c] (a row or column index)
  /// whenever it's a multiple of the box size - true for every real box
  /// boundary AND every constituent grid's outer edge in any of these
  /// layouts, since two 9x9 grids can only share exactly one box (what
  /// makes Samurai/Twin/Gattai-8/Sohei recognizable as that pattern at all)
  /// by sitting a multiple of `kBoxSize` apart - so every grid's origin,
  /// and therefore every one of its box boundaries and edges, always lands
  /// on a global multiple of `kBoxSize`. Using that directly - instead of
  /// asking whether two specific cells share a box - guarantees every
  /// vertical line lines up with every other vertical line at the same
  /// column across the whole shape, and likewise for rows, rather than
  /// relying on that falling out of the box-sharing check by coincidence.
  static bool _isBoxBoundary(int c) => c % kBoxSize == 0;

  @override
  Widget build(BuildContext context) {
    final shape = board.shape;
    final selectedValue = _hasSelection ? board.cellAt(selectedRow!, selectedCol!).value : 0;
    final resolvedHighlight = highlightColor.resolve(Theme.of(context).brightness);

    return AspectRatio(
      aspectRatio: shape.width / shape.height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline, width: 2),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: shape.width),
          itemCount: shape.height * shape.width,
          itemBuilder: (context, index) {
            final row = index ~/ shape.width;
            final col = index % shape.width;
            if (!shape.activeCells.contains((row, col))) {
              return const SizedBox.shrink();
            }

            final cell = board.cellAt(row, col);
            final isSelected = _hasSelection && row == selectedRow && col == selectedCol;

            final isPeer = highlightEnabled && !isSelected && _isPeer(row, col);

            final isSameValue = highlightEnabled &&
                !isSelected &&
                selectedValue != 0 &&
                cell.value == selectedValue;

            final isError = showErrors &&
                solution != null &&
                !cell.isEmpty &&
                cell.value != solution!.cellAt(row, col).value;

            return SudokuCellWidget(
              key: ValueKey('cell-$row-$col'),
              cell: cell,
              isSelected: isSelected,
              isPeerHighlighted: isPeer,
              isSameValueHighlighted: isSameValue,
              isError: isError,
              isThickRightBorder: col + 1 < shape.width && _isBoxBoundary(col + 1),
              isThickBottomBorder: row + 1 < shape.height && _isBoxBoundary(row + 1),
              isThickLeftBorder:
                  col > 0 && _isBoxBoundary(col) && !shape.activeCells.contains((row, col - 1)),
              isThickTopBorder:
                  row > 0 && _isBoxBoundary(row) && !shape.activeCells.contains((row - 1, col)),
              highlightedValue: highlightEnabled ? selectedValue : 0,
              highlightColor: resolvedHighlight,
              onTap: () => onCellTap(row, col),
            );
          },
        ),
      ),
    );
  }
}
