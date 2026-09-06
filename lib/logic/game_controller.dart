import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/board.dart';
import '../models/difficulty.dart';
import '../models/game_state.dart';
import '../models/leaderboard_entry.dart';
import '../models/settings.dart';
import '../services/game_persistence_service.dart';
import '../services/puzzle_generation_service.dart';
import '../services/sound_service.dart';
import 'candidates.dart';
import 'hint_engine.dart';
import 'leaderboard_controller.dart';
import 'service_providers.dart';
import 'settings_controller.dart';
import 'validator.dart';

/// Owns the currently active game (or `null` if none is running) and every
/// gameplay action: selection, number/notes input, undo/redo, hints,
/// pause/resume, the timer tick, and autosave.
///
/// Pure state-machine logic lives here so it stays independently testable;
/// only the puzzle generation call crosses into a background isolate.
class GameController extends Notifier<GameState?> {
  bool isGenerating = false;
  int _ticksSinceSave = 0;
  Timer? _saveDebounce;

  /// How long a routine edit (a keystroke, a notes toggle, undo/redo, ...)
  /// waits before actually hitting disk, coalescing a burst of edits into
  /// one write instead of one per edit. Game-ending transitions and
  /// lifecycle/back-navigation events bypass this via [saveNow] so they're
  /// never lost to an unflushed debounce if the app is killed right after.
  static const _saveDebounceDelay = Duration(milliseconds: 800);

  GamePersistenceService get _persistence => ref.read(gamePersistenceServiceProvider);
  SoundService get _sound => ref.read(soundServiceProvider);

  @override
  GameState? build() {
    ref.listen<Settings>(
      settingsControllerProvider,
      (previous, next) => _sound.enabled = next.soundEnabled,
      fireImmediately: true,
    );
    ref.onDispose(() => _saveDebounce?.cancel());
    return null;
  }

  Future<void> startNewGame(
    Difficulty difficulty, {
    required int maxMistakes,
    required bool errorLimitEnabled,
    required int maxHints,
  }) async {
    // Guards against a second generation racing this one - e.g. a
    // double-tapped difficulty button on Home - which would otherwise let
    // whichever isolate finishes last silently overwrite the other's state.
    if (isGenerating) return;
    isGenerating = true;
    state = null;
    try {
      final generated = await PuzzleGenerationService.generate(difficulty);
      state = GameState(
        board: generated.puzzle,
        solution: generated.solution,
        difficulty: difficulty,
        maxMistakes: maxMistakes,
        errorLimitEnabled: errorLimitEnabled,
        maxHints: maxHints,
      );
      await _persist();
    } finally {
      isGenerating = false;
    }
  }

  void restore(GameState saved) => state = saved;

  Future<void> abandonGame() async {
    state = null;
    await _persistence.clear();
    // savedGameProvider watches this controller's state directly and falls
    // back to persistence.load() only while it's null (see
    // saved_game_provider.dart), so clearing state already made it
    // re-check - now against the just-cleared store - with no invalidate
    // needed.
  }

  /// Forces an immediate write of the current state, bypassing (and
  /// cancelling) any pending debounced save. Used when the player is about
  /// to leave the game (back navigation, app backgrounded/closed) so
  /// nothing since the last debounced save is lost.
  Future<void> saveNow() {
    _saveDebounce?.cancel();
    _saveDebounce = null;
    return _persist();
  }

  /// Schedules a debounced save ([_saveDebounceDelay] after the last call),
  /// for routine edits where losing the last fraction of a second of
  /// progress to an app kill is an acceptable trade for not hitting disk on
  /// every keystroke. Game-ending transitions call [saveNow] instead.
  void _schedulePersist() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(_saveDebounceDelay, () {
      _saveDebounce = null;
      _persist();
    });
  }

  /// True once [s] shouldn't allow any gameplay action to mutate the board,
  /// notes, hint count or undo/redo stacks: paused, won, or lost. Every
  /// action below other than `togglePause` (which must still work *while*
  /// paused, to resume) checks this first via the `s == null || _locked(s)`
  /// pattern, in one place, so a future action can't repeat the
  /// pause-bypass bug where hints/undo/redo/notes stayed live while the
  /// board was hidden behind the paused overlay.
  bool _locked(GameState s) => s.isPaused || s.isWon || s.isGameOver;

  void selectCell(int row, int col) {
    final s = state;
    if (s == null || _locked(s)) return;
    state = s.copyWith(selectedRow: row, selectedCol: col);
  }

  void toggleNotesMode() {
    final s = state;
    if (s == null || _locked(s)) return;
    state = s.copyWith(notesMode: !s.notesMode);
  }

  void togglePause() {
    final s = state;
    if (s == null || s.isWon || s.isGameOver) return;
    state = s.copyWith(isPaused: !s.isPaused);
    _schedulePersist();
  }

  void tick() {
    final s = state;
    if (s == null || _locked(s)) return;
    state = s.copyWith(elapsedSeconds: s.elapsedSeconds + 1);
    if (++_ticksSinceSave >= 5) {
      _ticksSinceSave = 0;
      _persist();
    }
  }

  void inputNumber(int value) {
    final s = state;
    if (s == null || _locked(s) || !s.hasSelection) return;
    final row = s.selectedRow!, col = s.selectedCol!;
    final cell = s.board.cellAt(row, col);
    if (cell.isGiven) return;

    if (s.notesMode) {
      final hasNote = cell.notes.contains(value);
      // A note can always be cleared, but a new one may only be added if
      // it's still a legal candidate for the cell (not already placed in
      // its row/column/box) - notes for a digit that's plainly ruled out
      // aren't useful and would just clutter the cell.
      if (!hasNote && !Candidates.forCell(s.board, row, col).contains(value)) {
        _sound.error();
        return;
      }
      final newNotes = {...cell.notes};
      if (hasNote) {
        newNotes.remove(value);
      } else {
        newNotes.add(value);
      }
      final newBoard = s.board.setCell(row, col, cell.copyWith(notes: newNotes));
      state = _withHistory(s, newBoard);
      _sound.tap();
      _schedulePersist();
      return;
    }

    if (cell.value == value) return;

    final isCorrect = s.solution.cellAt(row, col).value == value;
    // Only clear this cell's own notes - and strip the matching note from
    // peers - once the entry is confirmed correct. A wrong guess shouldn't
    // erase pencil marks: erasing the wrong value (see eraseSelected) should
    // bring them right back.
    final placedBoard = s.board.setCell(row, col, cell.copyWith(value: value, clearNotes: isCorrect));
    final newBoard = isCorrect ? _stripNoteFromPeers(placedBoard, row, col, value) : placedBoard;

    var newState = _withHistory(s, newBoard).copyWith(
      mistakes: s.mistakes + (isCorrect ? 0 : 1),
    );

    if (isCorrect) {
      _sound.tap();
    } else {
      _sound.error();
    }

    if (Validator.isSolved(newBoard)) {
      newState = newState.copyWith(isWon: true);
      _sound.win();
      _recordWin(s.difficulty, newState.elapsedSeconds);
    }

    state = newState;
    // A win needs to survive an app kill immediately after it happens (see
    // the isWon-persistence fix), so flush right away instead of debouncing
    // - every other routine entry can wait and be coalesced.
    if (newState.isWon) {
      saveNow();
    } else {
      _schedulePersist();
    }
  }

  void eraseSelected() {
    final s = state;
    if (s == null || _locked(s) || !s.hasSelection) return;
    final row = s.selectedRow!, col = s.selectedCol!;
    final cell = s.board.cellAt(row, col);
    if (cell.isGiven || (cell.isEmpty && cell.notes.isEmpty)) return;
    // Erasing an empty cell clears its pencil marks (that's the point of
    // pressing erase there). Erasing a placed value keeps any notes the
    // cell already had, so undoing a wrong guess brings them right back.
    final newCell = cell.isEmpty ? cell.copyWith(clearNotes: true) : cell.copyWith(value: 0);
    final newBoard = s.board.setCell(row, col, newCell);
    state = _withHistory(s, newBoard);
    _schedulePersist();
  }

  void undo() {
    final s = state;
    if (s == null || _locked(s) || !s.canUndo) return;
    final previous = s.undoStack.last;
    state = s.copyWith(
      board: previous,
      undoStack: s.undoStack.sublist(0, s.undoStack.length - 1),
      redoStack: [...s.redoStack, s.board],
    );
    _schedulePersist();
  }

  void redo() {
    final s = state;
    if (s == null || _locked(s) || !s.canRedo) return;
    final next = s.redoStack.last;
    state = s.copyWith(
      board: next,
      redoStack: s.redoStack.sublist(0, s.redoStack.length - 1),
      undoStack: [...s.undoStack, s.board],
    );
    _schedulePersist();
  }

  /// Fills the pencil-mark notes of every empty cell with its currently
  /// legal candidates, so the player doesn't have to note them by hand.
  void autoFillNotes() {
    final s = state;
    if (s == null || _locked(s)) return;
    final candidates = Candidates.forBoard(s.board);
    var newBoard = s.board;
    for (var r = 0; r < kBoardSize; r++) {
      for (var c = 0; c < kBoardSize; c++) {
        final cell = newBoard.cellAt(r, c);
        if (!cell.isEmpty) continue;
        newBoard = newBoard.setCell(r, c, cell.copyWith(notes: candidates[r][c]));
      }
    }
    state = _withHistory(s, newBoard);
    _sound.tap();
    _schedulePersist();
  }

  /// Places the next logically derivable number (see [HintEngine]) and
  /// returns the [HintStep] taken - the UI (see `ui/hint_text.dart`) turns
  /// this into a localized explanation - or `null` if no hint could be given
  /// (no hints left, game finished/paused, or a wrong entry needs clearing
  /// first - see [_hasWrongEntry]).
  Future<HintStep?> useHint() async {
    final s = state;
    if (s == null || _locked(s) || s.hintsRemaining <= 0) return null;
    // A wrong-but-not-rule-breaking entry (e.g. a digit that's correct
    // nowhere else in its row/column/box but isn't what the unique solution
    // needs here) still counts as "placed" for HintEngine's candidate
    // computation, since HintEngine only sees the board, not the solution.
    // That can corrupt deductions elsewhere - e.g. ruling out the correct
    // digit for a peer cell - and produce a "confident" hint that
    // contradicts the true solution. Refuse to hint until it's cleared.
    if (_hasWrongEntry(s)) return null;

    final logicalStep = HintEngine.nextLogicalStep(s.board);
    final HintStep step;
    if (logicalStep != null) {
      step = logicalStep;
    } else {
      final pos = _firstEmptyCell(s.board);
      if (pos == null) return null;
      // No implemented technique applies: reveal the solution directly.
      // SolvingTechnique.backtracking marks this fallback for the UI.
      step = HintStep(
        row: pos.$1,
        col: pos.$2,
        value: s.solution.cellAt(pos.$1, pos.$2).value,
        technique: SolvingTechnique.backtracking,
      );
    }

    final cell = s.board.cellAt(step.row, step.col);
    final placedBoard = s.board.setCell(step.row, step.col, cell.copyWith(value: step.value, clearNotes: true));
    final newBoard = _stripNoteFromPeers(placedBoard, step.row, step.col, step.value);

    var newState = _withHistory(s, newBoard).copyWith(
      hintsUsed: s.hintsUsed + 1,
      selectedRow: step.row,
      selectedCol: step.col,
    );

    if (Validator.isSolved(newBoard)) {
      newState = newState.copyWith(isWon: true);
      _sound.win();
      _recordWin(s.difficulty, newState.elapsedSeconds);
    }

    state = newState;
    // See inputNumber: a win is flushed immediately rather than debounced.
    if (newState.isWon) {
      await saveNow();
    } else {
      _schedulePersist();
    }
    return step;
  }

  void _recordWin(Difficulty difficulty, int elapsedSeconds) {
    ref.read(leaderboardControllerProvider.notifier).addEntry(
          LeaderboardEntry(
            difficulty: difficulty,
            elapsedSeconds: elapsedSeconds,
            achievedAt: DateTime.now(),
          ),
        );
  }

  GameState _withHistory(GameState s, Board newBoard) {
    const maxHistory = 100;
    final newUndo = [...s.undoStack, s.board];
    if (newUndo.length > maxHistory) newUndo.removeAt(0);
    return s.copyWith(board: newBoard, undoStack: newUndo, redoStack: const []);
  }

  /// Removes [value] from the pencil marks of every peer (same row, column
  /// and box) of (row, col) - a common QoL touch once a number is placed.
  Board _stripNoteFromPeers(Board board, int row, int col, int value) {
    var result = board;
    void stripAt(int r, int c) {
      if (r == row && c == col) return;
      final cell = result.cellAt(r, c);
      if (cell.notes.contains(value)) {
        result = result.setCell(r, c, cell.copyWith(notes: {...cell.notes}..remove(value)));
      }
    }

    for (var c = 0; c < kBoardSize; c++) {
      stripAt(row, c);
    }
    for (var r = 0; r < kBoardSize; r++) {
      stripAt(r, col);
    }
    final boxRow = (row ~/ kBoxSize) * kBoxSize;
    final boxCol = (col ~/ kBoxSize) * kBoxSize;
    for (var r = boxRow; r < boxRow + kBoxSize; r++) {
      for (var c = boxCol; c < boxCol + kBoxSize; c++) {
        stripAt(r, c);
      }
    }
    return result;
  }

  (int, int)? _firstEmptyCell(Board board) {
    for (var r = 0; r < kBoardSize; r++) {
      for (var c = 0; c < kBoardSize; c++) {
        if (board.cellAt(r, c).isEmpty) return (r, c);
      }
    }
    return null;
  }

  /// True if any non-given, non-empty cell holds a value that isn't what
  /// [GameState.solution] has there - a mistake the player hasn't erased
  /// yet, even though it may not break any row/column/box rule on its own.
  bool _hasWrongEntry(GameState s) {
    for (var r = 0; r < kBoardSize; r++) {
      for (var c = 0; c < kBoardSize; c++) {
        final cell = s.board.cellAt(r, c);
        if (cell.isGiven || cell.isEmpty) continue;
        if (cell.value != s.solution.cellAt(r, c).value) return true;
      }
    }
    return false;
  }

  Future<void> _persist() async {
    final s = state;
    if (s == null) return;
    // No need to invalidate savedGameProvider here - it watches this
    // controller's state directly (see saved_game_provider.dart), so Home
    // already sees every change with no extra disk read.
    await _persistence.save(s);
  }
}

final gameControllerProvider = NotifierProvider<GameController, GameState?>(GameController.new);
