import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../logic/hint_engine.dart';
import '../../logic/providers.dart';
import '../../models/board.dart';
import '../../models/board_layout.dart';
import '../../models/puzzle_shape.dart';
import '../../models/settings.dart';
import '../difficulty_labels.dart';
import '../format_duration.dart';
import '../hint_text.dart';
import '../widgets/game_toolbar_widget.dart';
import '../widgets/number_pad_widget.dart';
import '../widgets/sudoku_board_widget.dart';
import '../widgets/win_celebration.dart';
import 'settings_screen.dart';

/// Main gameplay screen: status bar (timer/mistakes), board, toolbar and
/// number pad. Drives the once-a-second timer tick and reacts to
/// win/game-over by showing the appropriate dialog exactly once.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> with WidgetsBindingObserver {
  Timer? _timer;
  bool _endDialogShown = false;

  /// The most recent hint, kept only so the board can narrow its peer
  /// highlight down to the specific unit that forced a hidden single (see
  /// [SudokuBoardWidget.hintFocusUnit]). Becomes irrelevant - and is ignored
  /// - the moment selection moves away from the hinted cell.
  HintStep? _lastHint;

  late ScaffoldMessengerState _messenger;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(gameControllerProvider.notifier).tick();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    // Don't leave a hint banner dangling on whatever screen comes next.
    _messenger.clearMaterialBanners();
    super.dispose();
  }

  // Flushes the current state to disk as soon as the app is backgrounded or
  // closed, rather than waiting for the timer tick's throttled autosave.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      ref.read(gameControllerProvider.notifier).saveNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    if (gameState == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if ((gameState.isWon || gameState.isGameOver) && !_endDialogShown) {
      _endDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (gameState.isWon) {
          _showWinDialog(gameState.elapsedSeconds);
        } else {
          _showGameOverDialog();
        }
      });
    }

    final remainingCounts = _remainingCounts(gameState.board);

    // Only apply the narrowed unit highlight while the hinted cell is still
    // the one selected - once the player moves on, the old hint no longer
    // means anything for whatever's selected now.
    final lastHint = _lastHint;
    final hintFocusUnit = (lastHint != null &&
            lastHint.singleKind == SingleKind.hidden &&
            gameState.selectedRow == lastHint.row &&
            gameState.selectedCol == lastHint.col)
        ? lastHint.hiddenUnit
        : null;

    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text(l10n.gameTitle(gameState.difficulty.label(l10n))),
        actions: [
          IconButton(
            tooltip: gameState.isPaused ? l10n.resume : l10n.pause,
            icon: Icon(gameState.isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: () => ref.read(gameControllerProvider.notifier).togglePause(),
          ),
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  _StatusBar(
                    elapsedSeconds: gameState.elapsedSeconds,
                    mistakes: gameState.mistakes,
                    maxMistakes: gameState.maxMistakes,
                    errorLimitEnabled: gameState.errorLimitEnabled,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Center(
                      child: gameState.isPaused
                          ? _PausedOverlay(
                              onResume: () => ref.read(gameControllerProvider.notifier).togglePause(),
                            )
                          : _Board(
                              layout: gameState.layout,
                              board: gameState.board,
                              solution: gameState.solution,
                              selectedRow: gameState.selectedRow,
                              selectedCol: gameState.selectedCol,
                              highlightEnabled: settings.highlightEnabled,
                              highlightColor: settings.highlightColor,
                              showErrors: settings.showErrors,
                              hintFocusUnit: hintFocusUnit,
                              onCellTap: (row, col) =>
                                  ref.read(gameControllerProvider.notifier).selectCell(row, col),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Undo/redo/notes/hint all already no-op while paused (see
                  // GameController._locked), but the board itself is hidden
                  // behind _PausedOverlay above - disable and dim these too
                  // so the whole screen reads as paused, not just the board.
                  IgnorePointer(
                    ignoring: gameState.isPaused,
                    child: Opacity(
                      opacity: gameState.isPaused ? 0.4 : 1,
                      child: Column(
                        children: [
                          GameToolbarWidget(
                            canUndo: gameState.canUndo,
                            canRedo: gameState.canRedo,
                            notesMode: gameState.notesMode,
                            autoSolveEnabled: gameState.autoSolveSingles,
                            hintsRemaining: gameState.hintsRemaining,
                            onUndo: () => ref.read(gameControllerProvider.notifier).undo(),
                            onRedo: () => ref.read(gameControllerProvider.notifier).redo(),
                            onToggleNotes: () => ref.read(gameControllerProvider.notifier).toggleNotesMode(),
                            onAutoFillNotes: () => ref.read(gameControllerProvider.notifier).autoFillNotes(),
                            onToggleAutoSolve: () =>
                                ref.read(gameControllerProvider.notifier).toggleAutoSolveSingles(),
                            onHint: _useHint,
                          ),
                          const SizedBox(height: 12),
                          NumberPadWidget(
                            remainingCounts: remainingCounts,
                            onNumberTap: (value) => ref.read(gameControllerProvider.notifier).inputNumber(value),
                            onEraseTap: () => ref.read(gameControllerProvider.notifier).eraseSelected(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Covers the AppBar back arrow and system back gesture: neither goes
        // through _leaveToMenu, so flush explicitly on the way out.
        if (didPop) ref.read(gameControllerProvider.notifier).saveNow();
      },
      child: scaffold,
    );
  }

  Map<int, int> _remainingCounts(Board board) {
    // A solved board holds each digit exactly once per box - true even on
    // Samurai, where a shared box's single physical cell simultaneously
    // satisfies both grids it belongs to - so the number of box units
    // (already deduplicated by PuzzleShape for a shared box) is exactly
    // how many cells will hold each digit once everything's filled in: 9
    // for a classic board, 41 for Samurai (5 grids' 9 boxes each, minus
    // the 4 that are shared and so counted only once).
    final target = board.shape.units.where((u) => u.kind == UnitKind.box).length;
    final counts = <int, int>{for (var v = 1; v <= 9; v++) v: target};
    for (final (r, c) in board.shape.activeCells) {
      final value = board.cellAt(r, c).value;
      if (value != 0) counts[value] = counts[value]! - 1;
    }
    return counts;
  }

  void _useHint() {
    // Only peeks - selects the hinted cell and shows its explanation/
    // highlight - without placing the value. The value is placed by
    // confirmHint once the player taps "Got it" below.
    final step = ref.read(gameControllerProvider.notifier).peekHint();
    if (step == null) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _lastHint = step);

    // A banner (not a snackbar) so the explanation - and the board's unit
    // highlight while it's up - stay put until the player is done reading,
    // rather than racing a timeout.
    _messenger
      ..clearMaterialBanners()
      ..showMaterialBanner(
        MaterialBanner(
          leading: const Icon(Icons.lightbulb_outline),
          content: Text(describeHint(step, l10n)),
          actions: [
            TextButton(
              onPressed: () {
                _messenger.hideCurrentMaterialBanner();
                ref.read(gameControllerProvider.notifier).confirmHint(step);
                if (mounted) setState(() => _lastHint = null);
              },
              child: Text(l10n.hintDismiss),
            ),
          ],
        ),
      );
  }

  Future<void> _leaveToMenu() async {
    await ref.read(gameControllerProvider.notifier).abandonGame();
    if (!mounted) return;
    Navigator.of(context).pop(); // close dialog
    Navigator.of(context).pop(); // back to Home
  }

  void _showWinDialog(int elapsedSeconds) {
    final l10n = AppLocalizations.of(context)!;
    showWinCelebration(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.wonTitle),
        content: Text(l10n.wonMessage(formatDuration(elapsedSeconds))),
        actions: [
          TextButton(onPressed: _leaveToMenu, child: Text(l10n.backToMenu)),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.gameOverTitle),
        content: Text(l10n.gameOverMessage),
        actions: [
          TextButton(onPressed: _leaveToMenu, child: Text(l10n.backToMenu)),
        ],
      ),
    );
  }
}

/// Renders [SudokuBoardWidget], wrapped in a pinch-zoom/pan
/// [InteractiveViewer] for Samurai - whose 21x21 cross has far more detail
/// than fits legibly on a phone screen at once - and left unwrapped for the
/// classic board, which already fits comfortably.
class _Board extends StatelessWidget {
  final BoardLayout layout;
  final Board board;
  final Board? solution;
  final int? selectedRow;
  final int? selectedCol;
  final bool highlightEnabled;
  final HighlightColor highlightColor;
  final bool showErrors;
  final HintUnitType? hintFocusUnit;
  final void Function(int row, int col) onCellTap;

  const _Board({
    required this.layout,
    required this.board,
    required this.solution,
    required this.selectedRow,
    required this.selectedCol,
    required this.highlightEnabled,
    required this.highlightColor,
    required this.showErrors,
    required this.hintFocusUnit,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    final isClassic = layout == BoardLayout.classic;
    final boardWidget = SudokuBoardWidget(
      board: board,
      solution: solution,
      selectedRow: selectedRow,
      selectedCol: selectedCol,
      highlightEnabled: highlightEnabled,
      highlightColor: highlightColor,
      showErrors: showErrors,
      hintFocusUnit: hintFocusUnit,
      // A bit smaller than the largest size that would still fit each of
      // Samurai's much denser cells, so digits and notes read a little
      // airier there instead of always filling every available pixel.
      // Classic keeps its usual size unchanged.
      fontScale: isClassic ? 1 : 0.75,
      onCellTap: onCellTap,
    );
    if (isClassic) return boardWidget;
    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: boardWidget,
    );
  }
}

class _StatusBar extends StatelessWidget {
  final int elapsedSeconds;
  final int mistakes;
  final int maxMistakes;
  final bool errorLimitEnabled;

  const _StatusBar({
    required this.elapsedSeconds,
    required this.mistakes,
    required this.maxMistakes,
    required this.errorLimitEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.timer_outlined, size: 18),
            const SizedBox(width: 4),
            Text(formatDuration(elapsedSeconds), style: theme.textTheme.titleMedium),
          ],
        ),
        if (errorLimitEnabled)
          Row(
            children: [
              const Icon(Icons.error_outline, size: 18),
              const SizedBox(width: 4),
              Text('$mistakes / $maxMistakes', style: theme.textTheme.titleMedium),
            ],
          ),
      ],
    );
  }
}

class _PausedOverlay extends StatelessWidget {
  final VoidCallback onResume;

  const _PausedOverlay({required this.onResume});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.pause_circle_outline, size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        Text(l10n.paused, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onResume,
          icon: const Icon(Icons.play_arrow),
          label: Text(l10n.resume),
        ),
      ],
    );
  }
}
