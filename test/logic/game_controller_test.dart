import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/logic/candidates.dart';
import 'package:mrsudoku/logic/generator.dart';
import 'package:mrsudoku/logic/providers.dart';
import 'package:mrsudoku/logic/validator.dart';
import 'package:mrsudoku/models/board.dart';
import 'package:mrsudoku/models/board_layout.dart';
import 'package:mrsudoku/models/cell.dart';
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
    await controller.startNewGame(Difficulty.easy, maxMistakes: 3, errorLimitEnabled: true, maxHints: 5);
  });

  tearDown(() => container.dispose());

  test('startNewGame produces a playable board with a valid, complete solution', () {
    expect(state().board.isFull, isFalse);
    expect(Validator.isSolved(state().solution), isTrue);
  });

  test(
    'starting another game at the same difficulty and layout consumes the puzzle prewarmed '
    'after the previous one started, and still produces a valid, independent puzzle',
    () async {
      // setUp already started one Easy/classic game, which itself kicks off
      // a prewarm for another Easy/classic puzzle - exactly the case this
      // exercises.
      final firstBoard = state().board;

      await controller.startNewGame(Difficulty.easy, maxMistakes: 3, errorLimitEnabled: true, maxHints: 5);

      expect(state().difficulty, Difficulty.easy);
      expect(state().layout, BoardLayout.classic);
      expect(Validator.isSolved(state().solution), isTrue);
      // Overwhelmingly unlikely to coincide by chance for an unseeded
      // generation - confirms this really is a fresh puzzle, not the same
      // board object reused.
      expect(state().board.toValueGrid(), isNot(firstBoard.toValueGrid()));
    },
  );

  test('a second concurrent startNewGame call is ignored while one is already generating', () async {
    // Kick off two overlapping calls (as a double-tapped difficulty button
    // on Home would) without awaiting the first.
    final first = controller.startNewGame(Difficulty.expert, maxMistakes: 3, errorLimitEnabled: true, maxHints: 5);
    final second = controller.startNewGame(Difficulty.medium, maxMistakes: 1, errorLimitEnabled: true, maxHints: 1);

    await Future.wait([first, second]);

    // The second call should have been a no-op, so the first call's
    // settings win rather than whichever isolate happened to finish last.
    expect(state().difficulty, Difficulty.expert);
    expect(state().maxHints, 5);
  });

  test('selecting a cell highlights it', () {
    final pos = _firstEmptyCell(state());

    controller.selectCell(pos.$1, pos.$2);

    expect(state().selectedRow, pos.$1);
    expect(state().selectedCol, pos.$2);
    expect(state().hasSelection, isTrue);
  });

  test('selecting the already-selected cell again deselects it', () {
    final pos = _firstEmptyCell(state());
    controller.selectCell(pos.$1, pos.$2);

    controller.selectCell(pos.$1, pos.$2);

    expect(state().selectedRow, isNull);
    expect(state().selectedCol, isNull);
    expect(state().hasSelection, isFalse);
  });

  test('selecting a different cell after deselecting selects that one normally', () {
    final first = _firstEmptyCell(state());
    controller.selectCell(first.$1, first.$2);
    controller.selectCell(first.$1, first.$2); // deselect

    final board = state().board;
    final second = [
      for (var r = 0; r < 9; r++)
        for (var c = 0; c < 9; c++)
          if (board.cellAt(r, c).isEmpty && (r, c) != first) (r, c),
    ].first;
    controller.selectCell(second.$1, second.$2);

    expect(state().selectedRow, second.$1);
    expect(state().selectedCol, second.$2);
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

  test('a new note can still be added to a cell holding a wrong guess', () {
    controller.restore(_fixtureState());
    controller.selectCell(0, 0);
    controller.inputNumber(3); // solution at (0, 0) is 5, so 3 is wrong
    expect(state().mistakes, 1);
    expect(state().board.cellAt(0, 0).value, 3);

    controller.toggleNotesMode();
    controller.inputNumber(7); // still a legal candidate ignoring the wrong 3

    expect(state().board.cellAt(0, 0).notes, contains(7));
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

  group('while paused', () {
    setUp(() => controller.togglePause());

    test('peekHint is a no-op', () {
      final before = state().hintsRemaining;

      final step = controller.peekHint();

      expect(step, isNull);
      expect(state().hintsRemaining, before);
    });

    test('undo and redo are no-ops', () {
      final pos = _firstEmptyCell(state());
      controller.togglePause(); // unpause just long enough to make a move
      controller.selectCell(pos.$1, pos.$2);
      controller.inputNumber(state().solution.cellAt(pos.$1, pos.$2).value);
      controller.togglePause(); // and re-pause before trying to undo it

      controller.undo();
      expect(state().board.cellAt(pos.$1, pos.$2).value, isNot(0));

      controller.togglePause();
      controller.undo();
      controller.togglePause();
      controller.redo();
      expect(state().board.cellAt(pos.$1, pos.$2).value, 0);
    });

    test('autoFillNotes is a no-op', () {
      controller.autoFillNotes();

      for (var r = 0; r < 9; r++) {
        for (var c = 0; c < 9; c++) {
          expect(state().board.cellAt(r, c).notes, isEmpty);
        }
      }
    });

    test('toggleNotesMode is a no-op', () {
      final before = state().notesMode;

      controller.toggleNotesMode();

      expect(state().notesMode, before);
    });

    test('togglePause itself still works, to resume', () {
      expect(state().isPaused, isTrue);

      controller.togglePause();

      expect(state().isPaused, isFalse);
    });
  });

  test('peekHint selects the hinted cell but does not place its value or spend a hint', () {
    final before = state().hintsRemaining;

    final step = controller.peekHint();

    expect(step, isNotNull);
    expect(state().hintsRemaining, before, reason: 'peeking alone must not spend a hint');
    expect(state().board.cellAt(step!.row, step.col).value, 0);
    expect(state().selectedRow, step.row);
    expect(state().selectedCol, step.col);
  });

  test('confirmHint places the value and spends exactly one hint', () {
    final before = state().hintsRemaining;
    final step = controller.peekHint()!;

    controller.confirmHint(step);

    expect(state().hintsRemaining, before - 1);
    expect(state().board.cellAt(step.row, step.col).value, step.value);
  });

  test('confirmHint is a no-op if the target cell was filled in the meantime', () {
    final step = controller.peekHint()!;
    final before = state().hintsRemaining;
    // Simulate the player entering something else there while the hint's
    // banner was still up, before tapping "Got it" - peekHint already
    // selected the cell, so it's ready for input without selecting it again
    // (which would now deselect it instead - see selectCell's toggle).
    final otherValue = (step.value % 9) + 1;
    controller.inputNumber(otherValue);

    controller.confirmHint(step);

    expect(state().hintsRemaining, before, reason: 'a stale confirm must not spend a hint either');
    expect(state().board.cellAt(step.row, step.col).value, otherValue);
  });

  test('peekHint refuses to hint while a wrong entry is still on the board', () {
    controller.restore(_fixtureState());
    controller.selectCell(0, 0);
    controller.inputNumber(3); // solution at (0, 0) is 5, so 3 is wrong
    expect(state().mistakes, 1);
    final hintsBefore = state().hintsRemaining;

    final step = controller.peekHint();

    expect(step, isNull);
    expect(state().hintsRemaining, hintsBefore);
    // The wrong entry is untouched - a hint must not silently "fix" it.
    expect(state().board.cellAt(0, 0).value, 3);
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

  group('auto-solve singles', () {
    // The cascade paces itself 50ms apart (see
    // GameController._autoSolveStepDelay) so the player can see each cell
    // appear - real wall-clock time, since these are plain `test()`s, not
    // `testWidgets()` with a controllable fake clock. This comfortably
    // covers the 1-2 steps every fixture below needs.
    Future<void> waitForAutoSolve() => Future<void>.delayed(const Duration(milliseconds: 200));

    // Row 0 is given as [5,3,4,6,7,8,9,_,_] with everything else on the
    // board empty, so - looking at row 0 alone, since nothing else
    // constrains columns 7/8 or their box - (0,7) and (0,8) both start
    // with exactly candidates {1, 2}: not yet forced individually, but
    // placing either one removes it from the row and forces the other.
    GameState twoCellFixture({bool autoSolveSingles = false}) {
      final values = List.generate(9, (_) => List.filled(9, 0));
      values[0] = [5, 3, 4, 6, 7, 8, 9, 0, 0];
      final solutionValues = List.generate(9, (_) => List.filled(9, 0));
      solutionValues[0] = [5, 3, 4, 6, 7, 8, 9, 1, 2];

      return GameState(
        board: Board.fromValues(values),
        solution: Board.fromValues(solutionValues),
        difficulty: Difficulty.easy,
        autoSolveSingles: autoSolveSingles,
      );
    }

    test('is off by default', () {
      expect(state().autoSolveSingles, isFalse);
    });

    test('inputNumber does not auto-fill a newly forced single while off', () {
      controller.restore(twoCellFixture());
      controller.selectCell(0, 7);

      controller.inputNumber(1); // correct; would force (0, 8) -> 2 if on

      expect(state().board.cellAt(0, 8).value, 0);
    });

    test('inputNumber auto-fills a newly forced single once turned on, in one undo step', () async {
      controller.restore(twoCellFixture(autoSolveSingles: true));
      controller.selectCell(0, 7);

      controller.inputNumber(1); // correct; (0, 8)'s only candidate becomes 2
      await waitForAutoSolve();

      expect(state().board.cellAt(0, 7).value, 1);
      expect(state().board.cellAt(0, 8).value, 2);
      expect(state().mistakes, 0);

      // The cascade never pushes its own undo entry, so undoing the move
      // that triggered it reverts both cells at once.
      controller.undo();
      expect(state().board.cellAt(0, 7).value, 0);
      expect(state().board.cellAt(0, 8).value, 0);
    });

    test('toggleAutoSolveSingles fills an existing single, without adding its own undo step', () async {
      // (0, 7) is already filled as a *given* here (unlike the cascade
      // tests above, where it's filled by a move), so (0, 8) - candidates
      // {1, 2} before, now just {2} - is already forced before the toggle
      // is ever touched.
      final values = List.generate(9, (_) => List.filled(9, 0));
      values[0] = [5, 3, 4, 6, 7, 8, 9, 1, 0];
      final solutionValues = List.generate(9, (_) => List.filled(9, 0));
      solutionValues[0] = [5, 3, 4, 6, 7, 8, 9, 1, 2];
      controller.restore(GameState(
        board: Board.fromValues(values),
        solution: Board.fromValues(solutionValues),
        difficulty: Difficulty.easy,
      ));

      controller.toggleAutoSolveSingles();
      expect(state().autoSolveSingles, isTrue);
      await waitForAutoSolve();

      expect(state().board.cellAt(0, 8).value, 2);
      // The toggle itself doesn't touch the board, so it never pushed an
      // undo entry, and neither did the cascade it kicked off - there was
      // nothing to undo *to* before this test's very first move.
      expect(state().canUndo, isFalse);
    });

    test('toggleAutoSolveSingles does not fill anything while a wrong entry is on the board', () async {
      controller.restore(twoCellFixture());
      controller.selectCell(0, 7);
      controller.inputNumber(2); // wrong: solution says 1
      expect(state().mistakes, 1);

      controller.toggleAutoSolveSingles();
      await waitForAutoSolve();

      // The toggle still flips - it just can't safely deduce anything
      // while an unresolved wrong entry could corrupt the deduction (same
      // guard as hints - see peekHint's wrong-entry test above).
      expect(state().autoSolveSingles, isTrue);
      expect(state().board.cellAt(0, 8).value, 0);
    });

    test('toggling off again stops future moves from auto-filling', () {
      controller.restore(twoCellFixture(autoSolveSingles: true));
      controller.toggleAutoSolveSingles();
      expect(state().autoSolveSingles, isFalse);

      controller.selectCell(0, 7);
      controller.inputNumber(1);

      expect(state().board.cellAt(0, 8).value, 0);
    });

    test('can complete and win the game on its own', () async {
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
      final almostDone = [for (final row in solutionValues) [...row]];
      almostDone[0][8] = 0; // the only empty cell; forced to 2 by its row/column/box

      controller.restore(GameState(
        board: Board.fromValues(almostDone),
        solution: Board.fromValues(solutionValues),
        difficulty: Difficulty.easy,
      ));

      controller.toggleAutoSolveSingles();
      await waitForAutoSolve();

      expect(state().board.cellAt(0, 8).value, 2);
      expect(state().isWon, isTrue);

      // Let the leaderboard's async write finish before the container gets
      // disposed in tearDown (see the leaderboard test further below).
      await pumpEventQueue();
    });
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

  group('Samurai layout', () {
    test('can be completed and records a leaderboard entry tagged with the Samurai layout', () async {
      final shape = BoardLayout.samurai.shape;
      final generated = Generator.generate(Difficulty.easy, layout: BoardLayout.samurai, seed: 3);
      final solutionValues = generated.solution.toValueGrid();

      controller.restore(GameState(
        board: generated.solution, // start fully solved except for one cell, below
        solution: generated.solution,
        difficulty: Difficulty.easy,
        layout: BoardLayout.samurai,
      ));

      // Clear exactly one active cell so the game isn't already won, forcing
      // the player to make one final move.
      final lastCell = shape.activeCells.first;
      controller.restore(state().copyWith(
        board: state().board.setCell(lastCell.$1, lastCell.$2, const Cell()),
      ));
      expect(state().isWon, isFalse);

      controller.selectCell(lastCell.$1, lastCell.$2);
      controller.inputNumber(solutionValues[lastCell.$1][lastCell.$2]);

      expect(state().isWon, isTrue);
      expect(state().board.shape.activeCells, shape.activeCells);

      await pumpEventQueue();
      final leaderboard = container.read(leaderboardControllerProvider);
      expect(leaderboard, hasLength(1));
      expect(leaderboard.single.difficulty, Difficulty.easy);
      expect(leaderboard.single.layout, BoardLayout.samurai);
    });
  });
}
