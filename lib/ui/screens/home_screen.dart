import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../logic/providers.dart';
import '../../models/difficulty.dart';
import '../../models/game_state.dart';
import '../../models/settings.dart';
import '../difficulty_labels.dart';
import '../format_duration.dart';
import '../widgets/leaderboard_widget.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

/// Landing screen: offers to continue a saved game (if any) and lets the
/// player start a new one at a chosen difficulty.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedGame = ref.watch(savedGameProvider);
    final settings = ref.watch(settingsControllerProvider);
    final leaderboard = ref.watch(leaderboardControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('mrsudoku'),
        actions: [
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
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.grid_on_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Sudoku', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 32),
                  savedGame.when(
                    data: (saved) => saved == null
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 28),
                            child: FilledButton.icon(
                              onPressed: () => _continueGame(context, ref, saved),
                              icon: const Icon(Icons.play_arrow),
                              label: Text(
                                l10n.resumeButtonLabel(
                                  saved.difficulty.label(l10n),
                                  formatDuration(saved.elapsedSeconds),
                                ),
                              ),
                            ),
                          ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  Text(l10n.newGame, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final difficulty in Difficulty.values)
                        OutlinedButton(
                          onPressed: () => _startNewGame(context, ref, difficulty, settings),
                          child: Text(difficulty.label(l10n)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  LeaderboardWidget(entries: leaderboard),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _continueGame(BuildContext context, WidgetRef ref, GameState saved) async {
    ref.read(gameControllerProvider.notifier).restore(saved);
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GameScreen()));
  }

  Future<void> _startNewGame(
    BuildContext context,
    WidgetRef ref,
    Difficulty difficulty,
    Settings settings,
  ) async {
    final navigator = Navigator.of(context);
    // Navigate immediately; GameScreen shows a loading spinner while the
    // puzzle is generated on a background isolate (see
    // PuzzleGenerationService), so the UI never blocks.
    unawaited(navigator.push(MaterialPageRoute(builder: (_) => const GameScreen())));
    await ref.read(gameControllerProvider.notifier).startNewGame(
          difficulty,
          maxMistakes: settings.maxMistakes,
          errorLimitEnabled: settings.errorLimitEnabled,
          maxHints: settings.maxHints,
        );
  }
}
