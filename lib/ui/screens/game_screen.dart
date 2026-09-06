import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../logic/providers.dart';
import '../../models/board.dart';
import '../../models/difficulty.dart';
import '../format_duration.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(gameControllerProvider.notifier).tick();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
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

    final scaffold = Scaffold(
      appBar: AppBar(
        title: Text('Sudoku - ${gameState.difficulty.label}'),
        actions: [
          IconButton(
            tooltip: gameState.isPaused ? 'Fortsetzen' : 'Pausieren',
            icon: Icon(gameState.isPaused ? Icons.play_arrow : Icons.pause),
            onPressed: () => ref.read(gameControllerProvider.notifier).togglePause(),
          ),
          IconButton(
            tooltip: 'Einstellungen',
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
                          : SudokuBoardWidget(
                              board: gameState.board,
                              solution: gameState.solution,
                              selectedRow: gameState.selectedRow,
                              selectedCol: gameState.selectedCol,
                              highlightEnabled: settings.highlightEnabled,
                              showErrors: settings.showErrors,
                              onCellTap: (row, col) =>
                                  ref.read(gameControllerProvider.notifier).selectCell(row, col),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GameToolbarWidget(
                    canUndo: gameState.canUndo,
                    canRedo: gameState.canRedo,
                    notesMode: gameState.notesMode,
                    hintsRemaining: gameState.hintsRemaining,
                    onUndo: () => ref.read(gameControllerProvider.notifier).undo(),
                    onRedo: () => ref.read(gameControllerProvider.notifier).redo(),
                    onToggleNotes: () => ref.read(gameControllerProvider.notifier).toggleNotesMode(),
                    onAutoFillNotes: () => ref.read(gameControllerProvider.notifier).autoFillNotes(),
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
    final counts = <int, int>{for (var v = 1; v <= 9; v++) v: 9};
    for (var r = 0; r < kBoardSize; r++) {
      for (var c = 0; c < kBoardSize; c++) {
        final value = board.cellAt(r, c).value;
        if (value != 0) counts[value] = counts[value]! - 1;
      }
    }
    return counts;
  }

  Future<void> _useHint() async {
    final explanation = await ref.read(gameControllerProvider.notifier).useHint();
    if (explanation != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(explanation)));
    }
  }

  Future<void> _leaveToMenu() async {
    await ref.read(gameControllerProvider.notifier).abandonGame();
    if (!mounted) return;
    Navigator.of(context).pop(); // close dialog
    Navigator.of(context).pop(); // back to Home
  }

  void _showWinDialog(int elapsedSeconds) {
    showWinCelebration(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Geschafft! 🎉'),
        content: Text('Du hast das Rätsel in ${formatDuration(elapsedSeconds)} gelöst.'),
        actions: [
          TextButton(onPressed: _leaveToMenu, child: const Text('Zum Menü')),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: const Text('Du hast das Fehlerlimit erreicht.'),
        actions: [
          TextButton(onPressed: _leaveToMenu, child: const Text('Zum Menü')),
        ],
      ),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.pause_circle_outline, size: 64, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        Text('Pausiert', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onResume,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Fortsetzen'),
        ),
      ],
    );
  }
}
