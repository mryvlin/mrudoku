import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/logic/candidates.dart';
import 'package:mrsudoku/logic/providers.dart';
import 'package:mrsudoku/logic/validator.dart';
import 'package:mrsudoku/models/board.dart';
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

/// A near-empty board with a single given (4 at (0, 2)) so digit 4 is ruled
/// out as a note anywhere else in row 0, while (0, 0) and (0, 1) stay open
/// with several legal candidates (including 3 and 5) for the notes tests
/// below. The paired solution puts 5 at (0, 0) - the rest of the solution
/// grid is unused filler, just kept internally consistent.
GameState _fixtureState() {
  final values = List.generate(9, (_) => List.filled(9, 0));
  values[0][2] = 4;
  const solutionValues = [
    [5, 3, 4, 6, 7, 8, 9, 1, 2],
    [6, 7, 2, 1, 9, 5, 3, 4, 8],
    [1, 9, 8, 3, 4, 2, 5, 6, 7],
    [8, 5, 9, 7, 6, 1, 4, 2, 3],
    [4, 2, 6, 8, 5, 3, 7, 9, 1],
    [7, 1, 3, 9, 2, 4, 8, 5, 6],
    [9, 6, 1, 5, 3, 7, 2, 8, 4],
    [2, 8, 7, 4, 1, 9, 6, 3, 5],
    [3, 4, 5, 2, 8, 6, 1, 7, 9],
  ];

  return GameState(
    board: Board.fromValues(values),
    solution: Board.fromValues(solutionValues),
    difficulty: Difficulty.easy,
  );
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
    final candidate = Candidates.forCell(state().board, pos.$1, pos.$2).first;
    controller.selectCell(pos.$1, pos.$2);
    controller.toggleNotesMode();

    controller.inputNumber(candidate);

    final cell = state().board.cellAt(pos.$1, pos.$2);
    expect(cell.value, 0);
    expect(cell.notes, contains(candidate));
  });

  test('notes mode rejects a note for a digit already ruled out for the cell', () {
    controller.restore(_fixtureState());
    controller.selectCell(0, 1);
    controller.toggleNotesMode();

    controller.inputNumber(4); // already given at (0, 2), same row

    expect(state().board.cellAt(0, 1).notes, isEmpty);
  });

  test('notes mode allows a note for a digit that is still a legal candidate', () {
    controller.restore(_fixtureState());
    controller.selectCell(0, 1);
    controller.toggleNotesMode();

    controller.inputNumber(3);

    expect(state().board.cellAt(0, 1).notes, contains(3));
  });

  test('a wrong number entry does not strip a matching note from a peer cell', () {
    controller.restore(_fixtureState());

    controller.selectCell(0, 1);
    controller.toggleNotesMode();
    controller.inputNumber(3); // note in a peer of (0, 0)
    controller.toggleNotesMode();

    controller.selectCell(0, 0); // solution here is 5, so 3 is a wrong guess
    controller.inputNumber(3);

    expect(state().mistakes, 1);
    expect(state().board.cellAt(0, 1).notes, contains(3));
  });

  test('a correct number entry does strip the matching note from peer cells', () {
    controller.restore(_fixtureState());

    controller.selectCell(0, 1);
    controller.toggleNotesMode();
    controller.inputNumber(5); // note in a peer of (0, 0), for the same digit
    controller.toggleNotesMode();

    controller.selectCell(0, 0);
    controller.inputNumber(5); // matches the solution

    expect(state().mistakes, 0);
    expect(state().board.cellAt(0, 1).notes, isNot(contains(5)));
  });

  test("a wrong number entry keeps the cell's own notes, restored once erased", () {
    controller.restore(_fixtureState());
    controller.selectCell(0, 0);
    controller.toggleNotesMode();
    controller.inputNumber(2); // note on the cell itself
    controller.toggleNotesMode();

    controller.inputNumber(3); // solution at (0, 0) is 5, so 3 is wrong

    expect(state().mistakes, 1);
    expect(state().board.cellAt(0, 0).value, 3);

    controller.eraseSelected();

    final cell = state().board.cellAt(0, 0);
    expect(cell.value, 0);
    expect(cell.notes, contains(2));
  });

  test("a correct number entry clears the cell's own notes", () {
    controller.restore(_fixtureState());
    controller.selectCell(0, 0);
    controller.toggleNotesMode();
    controller.inputNumber(2);
    controller.toggleNotesMode();

    controller.inputNumber(5); // matches the solution

    expect(state().mistakes, 0);
    expect(state().board.cellAt(0, 0).notes, isEmpty);
  });

  test('erasing an empty cell still clears its own pencil marks', () {
    controller.restore(_fixtureState());
    controller.selectCell(0, 0);
    controller.toggleNotesMode();
    controller.inputNumber(2);
    controller.toggleNotesMode();
    expect(state().board.cellAt(0, 0).notes, contains(2));

    controller.eraseSelected();

    final cell = state().board.cellAt(0, 0);
    expect(cell.value, 0);
    expect(cell.notes, isEmpty);
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
