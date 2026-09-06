import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/logic/hint_engine.dart';
import 'package:mrsudoku/models/board.dart';
import 'package:mrsudoku/models/settings.dart';
import 'package:mrsudoku/ui/widgets/sudoku_board_widget.dart';
import 'package:mrsudoku/ui/widgets/sudoku_cell_widget.dart';

/// Set of every cell (as "row-col") the board currently reports as
/// peer-highlighted, for the given selection/focus-unit combination.
Future<Set<String>> _peerHighlightedCells(
  WidgetTester tester, {
  required int selectedRow,
  required int selectedCol,
  HintUnitType? hintFocusUnit,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SudokuBoardWidget(
          board: Board.empty(),
          solution: null,
          selectedRow: selectedRow,
          selectedCol: selectedCol,
          highlightEnabled: true,
          highlightColor: HighlightColor.red,
          showErrors: false,
          hintFocusUnit: hintFocusUnit,
          onCellTap: (row, col) {},
        ),
      ),
    ),
  );

  final result = <String>{};
  for (var r = 0; r < kBoardSize; r++) {
    for (var c = 0; c < kBoardSize; c++) {
      final widget = tester.widget<SudokuCellWidget>(find.byKey(ValueKey('cell-$r-$c')));
      if (widget.isPeerHighlighted) result.add('$r-$c');
    }
  }
  return result;
}

void main() {
  const row = 4, col = 4; // center cell, box (1, 1)

  testWidgets('with no hint focus, the full row+column+box is highlighted', (tester) async {
    final highlighted = await _peerHighlightedCells(tester, selectedRow: row, selectedCol: col);

    for (var c = 0; c < kBoardSize; c++) {
      if (c != col) expect(highlighted, contains('$row-$c'), reason: 'row peer $row-$c');
    }
    for (var r = 0; r < kBoardSize; r++) {
      if (r != row) expect(highlighted, contains('$r-$col'), reason: 'column peer $r-$col');
    }
    expect(highlighted, contains('3-3'));
    // A cell sharing none of row/column/box must not be highlighted.
    expect(highlighted, isNot(contains('0-0')));
  });

  testWidgets('a row hint focus highlights only the row', (tester) async {
    final highlighted = await _peerHighlightedCells(
      tester,
      selectedRow: row,
      selectedCol: col,
      hintFocusUnit: HintUnitType.row,
    );

    expect(highlighted, {for (var c = 0; c < kBoardSize; c++) if (c != col) '$row-$c'});
  });

  testWidgets('a column hint focus highlights only the column', (tester) async {
    final highlighted = await _peerHighlightedCells(
      tester,
      selectedRow: row,
      selectedCol: col,
      hintFocusUnit: HintUnitType.column,
    );

    expect(highlighted, {for (var r = 0; r < kBoardSize; r++) if (r != row) '$r-$col'});
  });

  testWidgets('a box hint focus highlights only the 3x3 box', (tester) async {
    final highlighted = await _peerHighlightedCells(
      tester,
      selectedRow: row,
      selectedCol: col,
      hintFocusUnit: HintUnitType.box,
    );

    final expected = <String>{
      for (var r = 3; r < 6; r++)
        for (var c = 3; c < 6; c++)
          if (r != row || c != col) '$r-$c',
    };
    expect(highlighted, expected);
  });
}
