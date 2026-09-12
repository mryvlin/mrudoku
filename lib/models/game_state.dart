import 'board.dart';
import 'board_layout.dart';
import 'difficulty.dart';

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
  final BoardLayout layout;
  final int elapsedSeconds;
  final int mistakes;
  final int maxMistakes;
  final bool errorLimitEnabled;
  final int hintsUsed;
  final int maxHints;
  final bool isPaused;
  final bool isWon;
  final bool notesMode;

  /// When on, any cell left with exactly one legal candidate (a "naked
  /// single") is filled in automatically after every move - see
  /// [GameController._applyAutoSolve].
  final bool autoSolveSingles;
  final int? selectedRow;
  final int? selectedCol;
  final List<Board> undoStack;
  final List<Board> redoStack;

  const GameState({
    required this.board,
    required this.solution,
    required this.difficulty,
    this.layout = BoardLayout.classic,
    this.elapsedSeconds = 0,
    this.mistakes = 0,
    this.maxMistakes = 3,
    this.errorLimitEnabled = true,
    this.hintsUsed = 0,
    this.maxHints = 5,
    this.isPaused = false,
    this.isWon = false,
    this.notesMode = false,
    this.autoSolveSingles = false,
    this.selectedRow,
    this.selectedCol,
    this.undoStack = const [],
    this.redoStack = const [],
  });

  bool get hasSelection => selectedRow != null && selectedCol != null;
  int get hintsRemaining => (maxHints - hintsUsed).clamp(0, maxHints);
  bool get isGameOver => errorLimitEnabled && mistakes >= maxMistakes;
  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;

  GameState copyWith({
    Board? board,
    Board? solution,
    Difficulty? difficulty,
    BoardLayout? layout,
    int? elapsedSeconds,
    int? mistakes,
    int? maxMistakes,
    bool? errorLimitEnabled,
    int? hintsUsed,
    int? maxHints,
    bool? isPaused,
    bool? isWon,
    bool? notesMode,
    bool? autoSolveSingles,
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
      layout: layout ?? this.layout,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      mistakes: mistakes ?? this.mistakes,
      maxMistakes: maxMistakes ?? this.maxMistakes,
      errorLimitEnabled: errorLimitEnabled ?? this.errorLimitEnabled,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      maxHints: maxHints ?? this.maxHints,
      isPaused: isPaused ?? this.isPaused,
      isWon: isWon ?? this.isWon,
      notesMode: notesMode ?? this.notesMode,
      autoSolveSingles: autoSolveSingles ?? this.autoSolveSingles,
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
        'layout': layout.name,
        'elapsedSeconds': elapsedSeconds,
        'mistakes': mistakes,
        'maxMistakes': maxMistakes,
        'errorLimitEnabled': errorLimitEnabled,
        'hintsUsed': hintsUsed,
        'maxHints': maxHints,
        'notesMode': notesMode,
        'autoSolveSingles': autoSolveSingles,
        'isWon': isWon,
      };

  factory GameState.fromJson(Map<String, dynamic> json) {
    final layout = BoardLayout.values.firstWhere(
      (l) => l.name == json['layout'],
      orElse: () => BoardLayout.classic,
    );
    final shape = layout.shape;
    return GameState(
      board: Board.fromJson(json['board'] as Map<String, dynamic>, shape: shape),
      solution: Board.fromJson(json['solution'] as Map<String, dynamic>, shape: shape),
      difficulty: Difficulty.values.firstWhere((d) => d.name == json['difficulty']),
      layout: layout,
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
      mistakes: json['mistakes'] as int? ?? 0,
      maxMistakes: json['maxMistakes'] as int? ?? 3,
      errorLimitEnabled: json['errorLimitEnabled'] as bool? ?? true,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      maxHints: json['maxHints'] as int? ?? 5,
      notesMode: json['notesMode'] as bool? ?? false,
      autoSolveSingles: json['autoSolveSingles'] as bool? ?? false,
      isWon: json['isWon'] as bool? ?? false,
    );
  }
}
