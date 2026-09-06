import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/logic/candidates.dart';
import 'package:mrsudoku/logic/providers.dart';
import 'package:mrsudoku/models/difficulty.dart';
import 'package:mrsudoku/models/game_state.dart';
import 'package:mrsudoku/ui/screens/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

(int, int) _firstEmptyCell(GameState state) {
  for (var r = 0; r < 9; r++) {
    for (var c = 0; c < 9; c++) {
      if (state.board.cellAt(r, c).isEmpty) return (r, c);
    }
  }
  throw StateError('no empty cell found');
}

Future<ProviderContainer> _startedContainer(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final container = ProviderContainer();
  addTearDown(container.dispose);
  // startNewGame -> PuzzleGenerationService.generate uses compute(), which
  // spawns a real isolate. That needs genuine event-loop pumping, which the
  // fake-time zone testWidgets normally runs in does not provide - hence
  // runAsync (see WidgetTester.runAsync docs on real async work in tests).
  await tester.runAsync(
    () => container.read(gameControllerProvider.notifier).startNewGame(
      Difficulty.easy,
      maxMistakes: 3,
      errorLimitEnabled: true,
    ),
  );

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: GameScreen()),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  testWidgets('tapping a cell then a number enters that value on the board', (tester) async {
    final container = await _startedContainer(tester);
    final pos = _firstEmptyCell(container.read(gameControllerProvider)!);
    final correctValue =
        container.read(gameControllerProvider)!.solution.cellAt(pos.$1, pos.$2).value;

    await tester.tap(find.byKey(ValueKey('cell-${pos.$1}-${pos.$2}')));
    await tester.pump();
    await tester.tap(find.byKey(ValueKey('numpad-$correctValue')));
    await tester.pump();

    expect(
      container.read(gameControllerProvider)!.board.cellAt(pos.$1, pos.$2).value,
      correctValue,
    );
  });

  testWidgets('notes mode enters a pencil mark instead of a value', (tester) async {
    final container = await _startedContainer(tester);
    final pos = _firstEmptyCell(container.read(gameControllerProvider)!);
    final candidate =
        Candidates.forCell(container.read(gameControllerProvider)!.board, pos.$1, pos.$2).first;

    await tester.tap(find.byKey(ValueKey('cell-${pos.$1}-${pos.$2}')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('toolbar-notes')));
    await tester.pump();
    await tester.tap(find.byKey(ValueKey('numpad-$candidate')));
    await tester.pump();

    final cell = container.read(gameControllerProvider)!.board.cellAt(pos.$1, pos.$2);
    expect(cell.value, 0);
    expect(cell.notes, contains(candidate));
  });

  testWidgets('undo button reverts the last entered value', (tester) async {
    final container = await _startedContainer(tester);
    final pos = _firstEmptyCell(container.read(gameControllerProvider)!);
    final correctValue =
        container.read(gameControllerProvider)!.solution.cellAt(pos.$1, pos.$2).value;

    await tester.tap(find.byKey(ValueKey('cell-${pos.$1}-${pos.$2}')));
    await tester.pump();
    await tester.tap(find.byKey(ValueKey('numpad-$correctValue')));
    await tester.pump();
    expect(
      container.read(gameControllerProvider)!.board.cellAt(pos.$1, pos.$2).value,
      correctValue,
    );

    await tester.tap(find.byKey(const ValueKey('toolbar-undo')));
    await tester.pump();

    expect(container.read(gameControllerProvider)!.board.cellAt(pos.$1, pos.$2).value, 0);
  });
}
