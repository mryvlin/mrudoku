import 'board.dart';
import 'difficulty.dart';

/// Maximum number of hints available per game.
const int kMaxHints = 3;

/// Full state of one Sudoku game in progress: the mutable board, the
/// solution used for validation/hints, and all the bookkeeping the UI needs
/// (timer, mistakes, hints, notes mode, undo/redo, selection).
///
/// Immutable; every change produces a new [GameState] via [copyWith], which
/// keeps the Riverpod controller and the undo/redo stack simple.
class GameState {
  final Board board;
  final Board solution;
  final Difficulty difficulty;
  final int elapsedSeconds;
  final int mistakes;
  final int maxMistakes;
  final bool errorLimitEnabled;
  final int hintsUsed;
  final bool isPaused;
  final bool isWon;
  final bool notesMode;
  final int? selectedRow;
  final int? selectedCol;
  final List<Board> undoStack;
  final List<Board> redoStack;

  const GameState({
    required this.board,
    required this.solution,
    required this.difficulty,
    this.elapsedSeconds = 0,
    this.mistakes = 0,
    this.maxMistakes = 3,
    this.errorLimitEnabled = true,
    this.hintsUsed = 0,
    this.isPaused = false,
    this.isWon = false,
    this.notesMode = false,
    this.selectedRow,
    this.selectedCol,
    this.undoStack = const [],
    this.redoStack = const [],
  });

  bool get hasSelection => selectedRow != null && selectedCol != null;
  int get hintsRemaining => (kMaxHints - hintsUsed).clamp(0, kMaxHints);
  bool get isGameOver => errorLimitEnabled && mistakes >= maxMistakes;
  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  GameState copyWith({
    Board? board,
    Board? solution,
    Difficulty? difficulty,
    int? elapsedSeconds,
    int? mistakes,
    int? maxMistakes,
    bool? errorLimitEnabled,
    int? hintsUsed,
    bool? isPaused,
    bool? isWon,
    bool? notesMode,
    int? selectedRow,
    int? selectedCol,
    bool clearSelection = false,
    List<Board>? undoStack,
    List<Board>? redoStack,
  }) {
    return GameState(
      board: board ?? this.board,
      solution: solution ?? this.solution,
      difficulty: difficulty ?? this.difficulty,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      mistakes: mistakes ?? this.mistakes,
      maxMistakes: maxMistakes ?? this.maxMistakes,
      errorLimitEnabled: errorLimitEnabled ?? this.errorLimitEnabled,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      isPaused: isPaused ?? this.isPaused,
      isWon: isWon ?? this.isWon,
      notesMode: notesMode ?? this.notesMode,
      selectedRow: clearSelection ? null : (selectedRow ?? this.selectedRow),
      selectedCol: clearSelection ? null : (selectedCol ?? this.selectedCol),
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
    );
  }

  /// Persisted fields only - the undo/redo history is intentionally not
  /// saved (it is reset on app restart to keep the save file small).
  Map<String, dynamic> toJson() => {
        'board': board.toJson(),
        'solution': solution.toJson(),
        'difficulty': difficulty.name,
        'elapsedSeconds': elapsedSeconds,
        'mistakes': mistakes,
        'maxMistakes': maxMistakes,
        'errorLimitEnabled': errorLimitEnabled,
        'hintsUsed': hintsUsed,
        'notesMode': notesMode,
      };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
        board: Board.fromJson(json['board'] as Map<String, dynamic>),
        solution: Board.fromJson(json['solution'] as Map<String, dynamic>),
        difficulty: Difficulty.values.firstWhere((d) => d.name == json['difficulty']),
        elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
        mistakes: json['mistakes'] as int? ?? 0,
        maxMistakes: json['maxMistakes'] as int? ?? 3,
        errorLimitEnabled: json['errorLimitEnabled'] as bool? ?? true,
        hintsUsed: json['hintsUsed'] as int? ?? 0,
        notesMode: json['notesMode'] as bool? ?? false,
      );
}
