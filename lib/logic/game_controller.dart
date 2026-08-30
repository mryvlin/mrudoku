import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/board.dart';
import '../models/difficulty.dart';
import '../models/game_state.dart';
import '../models/settings.dart';
import '../services/game_persistence_service.dart';
import '../services/puzzle_generation_service.dart';
import '../services/sound_service.dart';
import 'candidates.dart';
import 'hint_engine.dart';
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

  GamePersistenceService get _persistence => ref.read(gamePersistenceServiceProvider);
  SoundService get _sound => ref.read(soundServiceProvider);

  @override
  GameState? build() {
    ref.listen<Settings>(
      settingsControllerProvider,
      (previous, next) => _sound.enabled = next.soundEnabled,
      fireImmediately: true,
    );
    return null;
  }

  Future<void> startNewGame(
    Difficulty difficulty, {
    required int maxMistakes,
    required bool errorLimitEnabled,
  }) async {
    isGenerating = true;
    state = null;
    final generated = await PuzzleGenerationService.generate(difficulty);
    state = GameState(
      board: generated.puzzle,
      solution: generated.solution,
      difficulty: difficulty,
      maxMistakes: maxMistakes,
      errorLimitEnabled: errorLimitEnabled,
    );
    isGenerating = false;
    await _persist();
  }

  void restore(GameState saved) => state = saved;

  Future<void> abandonGame() async {
    state = null;
    await _persistence.clear();
  }

  void selectCell(int row, int col) {
    final s = state;
    if (s == null || s.isGameOver || s.isWon) return;
    state = s.copyWith(selectedRow: row, selectedCol: col);
  }

  void toggleNotesMode() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(notesMode: !s.notesMode);
  }

  void togglePause() {
    final s = state;
    if (s == null || s.isWon || s.isGameOver) return;
    state = s.copyWith(isPaused: !s.isPaused);
    _persist();
  }

  void tick() {
    final s = state;
    if (s == null || s.isPaused || s.isWon || s.isGameOver) return;
    state = s.copyWith(elapsedSeconds: s.elapsedSeconds + 1);
    if (++_ticksSinceSave >= 5) {
      _ticksSinceSave = 0;
      _persist();
    }
  }

  void inputNumber(int value) {
    final s = state;
    if (s == null || s.isGameOver || s.isWon || s.isPaused || !s.hasSelection) return;
    final row = s.selectedRow!, col = s.selectedCol!;
    final cell = s.board.cellAt(row, col);
    if (cell.isGiven) return;

    if (s.notesMode) {
      final newNotes = {...cell.notes};
      if (!newNotes.remove(value)) newNotes.add(value);
      final newBoard = s.board.setCell(row, col, cell.copyWith(notes: newNotes));
      state = _withHistory(s, newBoard);
      _sound.tap();
      _persist();
      return;
    }

    if (cell.value == value) return;

    final isCorrect = s.solution.cellAt(row, col).value == value;
    final placedBoard = s.board.setCell(row, col, cell.copyWith(value: value, clearNotes: true));
    final newBoard = _stripNoteFromPeers(placedBoard, row, col, value);

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
    }

    state = newState;
    _persist();
  }

  void eraseSelected() {
    final s = state;
    if (s == null || s.isGameOver || s.isWon || s.isPaused || !s.hasSelection) return;
    final row = s.selectedRow!, col = s.selectedCol!;
    final cell = s.board.cellAt(row, col);
    if (cell.isGiven || (cell.isEmpty && cell.notes.isEmpty)) return;
    final newBoard = s.board.setCell(row, col, cell.copyWith(value: 0, clearNotes: true));
    state = _withHistory(s, newBoard);
    _persist();
  }

  void undo() {
    final s = state;
    if (s == null || !s.canUndo) return;
    final previous = s.undoStack.last;
    state = s.copyWith(
      board: previous,
      undoStack: s.undoStack.sublist(0, s.undoStack.length - 1),
      redoStack: [...s.redoStack, s.board],
    );
    _persist();
  }

  void redo() {
    final s = state;
    if (s == null || !s.canRedo) return;
    final next = s.redoStack.last;
    state = s.copyWith(
      board: next,
      redoStack: s.redoStack.sublist(0, s.redoStack.length - 1),
      undoStack: [...s.undoStack, s.board],
    );
    _persist();
  }

  /// Fills the pencil-mark notes of every empty cell with its currently
  /// legal candidates, so the player doesn't have to note them by hand.
  void autoFillNotes() {
    final s = state;
    if (s == null || s.isGameOver || s.isWon) return;
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
    _persist();
  }

  /// Places the next logically derivable number (see [HintEngine]) and
  /// returns a short explanation for the UI to display, or `null` if no
  /// hint could be given (no hints left, or game finished/paused).
  Future<String?> useHint() async {
    final s = state;
    if (s == null || s.isGameOver || s.isWon || s.hintsRemaining <= 0) return null;

    final step = HintEngine.nextLogicalStep(s.board);
    late final int row, col, value;
    late final String explanation;

    if (step != null) {
      row = step.row;
      col = step.col;
      value = step.value;
      explanation = '${step.technique.label}: ${step.explanation}';
    } else {
      final pos = _firstEmptyCell(s.board);
      if (pos == null) return null;
      row = pos.$1;
      col = pos.$2;
      value = s.solution.cellAt(row, col).value;
      explanation = 'Keine einfache Logik-Regel greift hier - die Lösung für diese Zelle wird '
          'direkt verraten.';
    }

    final cell = s.board.cellAt(row, col);
    final placedBoard = s.board.setCell(row, col, cell.copyWith(value: value, clearNotes: true));
    final newBoard = _stripNoteFromPeers(placedBoard, row, col, value);

    var newState = _withHistory(s, newBoard).copyWith(
      hintsUsed: s.hintsUsed + 1,
      selectedRow: row,
      selectedCol: col,
    );

    if (Validator.isSolved(newBoard)) {
      newState = newState.copyWith(isWon: true);
      _sound.win();
    }

    state = newState;
    await _persist();
    return explanation;
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

  Future<void> _persist() async {
    final s = state;
    if (s != null) await _persistence.save(s);
  }
}

final gameControllerProvider = NotifierProvider<GameController, GameState?>(GameController.new);
