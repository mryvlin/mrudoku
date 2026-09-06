import 'package:flutter/material.dart';

import '../../models/board.dart';
import '../../models/settings.dart';
import '../highlight_colors.dart';
import 'sudoku_cell_widget.dart';

/// Renders the full 9x9 grid, delegating each cell to [SudokuCellWidget] and
/// working out selection/peer/same-value/error highlighting.
///
/// Stays square and centered via [AspectRatio] so it scales cleanly from a
/// narrow phone in portrait mode up to a wide desktop browser window.
class SudokuBoardWidget extends StatelessWidget {
  final Board board;
  final Board? solution;
  final int? selectedRow;
  final int? selectedCol;
  final bool highlightEnabled;
  final HighlightColor highlightColor;
  final bool showErrors;
  final void Function(int row, int col) onCellTap;

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
  });

  bool get _hasSelection => selectedRow != null && selectedCol != null;

  bool _sameBox(int row, int col) {
    if (!_hasSelection) return false;
    return row ~/ kBoxSize == selectedRow! ~/ kBoxSize && col ~/ kBoxSize == selectedCol! ~/ kBoxSize;
  }

  @override
  Widget build(BuildContext context) {
    final selectedValue = _hasSelection ? board.cellAt(selectedRow!, selectedCol!).value : 0;
    final resolvedHighlight = highlightColor.resolve(Theme.of(context).brightness);

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline, width: 2),
        ),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: kBoardSize),
          itemCount: kBoardSize * kBoardSize,
          itemBuilder: (context, index) {
            final row = index ~/ kBoardSize;
            final col = index % kBoardSize;
            final cell = board.cellAt(row, col);
            final isSelected = _hasSelection && row == selectedRow && col == selectedCol;

            final isPeer = highlightEnabled &&
                _hasSelection &&
                !isSelected &&
                (row == selectedRow || col == selectedCol || _sameBox(row, col));

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
              isThickRightBorder: col % kBoxSize == kBoxSize - 1 && col != kBoardSize - 1,
              isThickBottomBorder: row % kBoxSize == kBoxSize - 1 && row != kBoardSize - 1,
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
