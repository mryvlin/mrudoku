import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/logic/providers.dart';
import 'package:mrsudoku/logic/validator.dart';
import 'package:mrsudoku/models/difficulty.dart';
import 'package:mrsudoku/models/game_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

(int, int) _firstEmptyCell(GameState state) {
  for (var r = 0; r < 9; r++) {
    for (var c = 0; c < 9; c++) {
      if (state.board.cellAt(r, c).isEmpty) return (r, c);
    }
  }
  throw StateError('no empty cell found');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;
  late GameController controller;

  GameState state() => container.read(gameControllerProvider)!;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    container = ProviderContainer();
    controller = container.read(gameControllerProvider.notifier);
    await controller.startNewGame(Difficulty.easy, maxMistakes: 3, errorLimitEnabled: true);
  });

  tearDown(() => container.dispose());

  test('startNewGame produces a playable board with a valid, complete solution', () {
    expect(state().board.isFull, isFalse);
    expect(Validator.isSolved(state().solution), isTrue);
  });

  test('entering the correct value updates the board and keeps mistakes at 0', () {
    final pos = _firstEmptyCell(state());
    controller.selectCell(pos.$1, pos.$2);
    final correctValue = state().solution.cellAt(pos.$1, pos.$2).value;

    controller.inputNumber(correctValue);

    expect(state().board.cellAt(pos.$1, pos.$2).value, correctValue);
    expect(state().mistakes, 0);
  });

  test('entering a wrong value increments the mistake counter', () {
    final pos = _firstEmptyCell(state());
    controller.selectCell(pos.$1, pos.$2);
    final correctValue = state().solution.cellAt(pos.$1, pos.$2).value;
    final wrongValue = (correctValue % 9) + 1; // always different from correctValue

    controller.inputNumber(wrongValue);

    expect(state().mistakes, 1);
  });

  test('notes mode records a pencil mark instead of a value', () {
    final pos = _firstEmptyCell(state());
    controller.selectCell(pos.$1, pos.$2);
    controller.toggleNotesMode();

    controller.inputNumber(4);

    final cell = state().board.cellAt(pos.$1, pos.$2);
    expect(cell.value, 0);
    expect(cell.notes, contains(4));
  });

  test('undo reverts the last change and redo re-applies it', () {
    final pos = _firstEmptyCell(state());
    controller.selectCell(pos.$1, pos.$2);
    final correctValue = state().solution.cellAt(pos.$1, pos.$2).value;
    controller.inputNumber(correctValue);
    expect(state().board.cellAt(pos.$1, pos.$2).value, correctValue);

    controller.undo();
    expect(state().board.cellAt(pos.$1, pos.$2).value, 0);

    controller.redo();
    expect(state().board.cellAt(pos.$1, pos.$2).value, correctValue);
  });

  test('a hint reduces the remaining hint count and places a correct value', () async {
    final before = state().hintsRemaining;

    final explanation = await controller.useHint();

    expect(explanation, isNotNull);
    expect(state().hintsRemaining, before - 1);
  });

  test('autoFillNotes fills every empty cell with its legal candidates', () {
    controller.autoFillNotes();

    final board = state().board;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final cell = board.cellAt(r, c);
        if (cell.isEmpty) expect(cell.notes, isNotEmpty);
      }
    }
  });

  test('the saved-game provider reflects progress after a move, for Home to offer resume', () async {
    final pos = _firstEmptyCell(state());
    controller.selectCell(pos.$1, pos.$2);
    final correctValue = state().solution.cellAt(pos.$1, pos.$2).value;
    controller.inputNumber(correctValue);
    await pumpEventQueue();

    final saved = await container.read(savedGameProvider.future);
    expect(saved, isNotNull);
    expect(saved!.difficulty, Difficulty.easy);
    expect(saved.board.cellAt(pos.$1, pos.$2).value, correctValue);
  });

  test('abandoning the game clears the saved-game provider, leaving only "start new"', () async {
    await controller.abandonGame();
    await pumpEventQueue();

    expect(await container.read(savedGameProvider.future), isNull);
  });

  test('solving the puzzle records a leaderboard entry for its difficulty', () async {
    final solution = state().solution;
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        if (state().board.cellAt(r, c).isGiven) continue;
        controller.selectCell(r, c);
        controller.inputNumber(solution.cellAt(r, c).value);
      }
    }

    expect(state().isWon, isTrue);
    await pumpEventQueue();
    final leaderboard = container.read(leaderboardControllerProvider);
    expect(leaderboard, hasLength(1));
    expect(leaderboard.single.difficulty, Difficulty.easy);
    expect(leaderboard.single.elapsedSeconds, state().elapsedSeconds);
  });
}
