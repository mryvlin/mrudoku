import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../logic/providers.dart';
import '../../models/board_layout.dart';
import '../../models/difficulty.dart';
import '../../models/game_state.dart';
import '../../models/settings.dart';
import '../board_layout_labels.dart';
import '../difficulty_labels.dart';
import '../format_duration.dart';
import '../home_palette.dart';
import '../widgets/leaderboard_widget.dart';
import 'game_screen.dart';
import 'settings_screen.dart';

/// Landing screen: offers to continue a saved game (if any) and lets the
/// player start a new one at a chosen board layout and difficulty. Uses a
/// fixed dark design ([HomePalette]) rather than the app's theme, since this
/// is meant to be the screen's one look regardless of the user's
/// light/dark/system theme setting.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Sits true from the first tap on "Continue"/a difficulty button until
  // GameScreen has been pushed, so a double-tap (or tapping a second
  // difficulty before the first finishes generating) can't push two
  // GameScreen routes or race two concurrent generations.
  bool _navigating = false;

  /// Which layout the difficulty buttons below start a new game on. Purely
  /// local UI state - the choice made here is passed straight through to
  /// [GameController.startNewGame] and doesn't need to persist across app
  /// launches.
  BoardLayout _selectedLayout = BoardLayout.classic;

  /// Purely a visual "last chosen" highlight - tapping a difficulty starts a
  /// game immediately (as before), this just tracks which pill to show
  /// selected.
  Difficulty _selectedDifficulty = Difficulty.medium;

  @override
  Widget build(BuildContext context) {
    final savedGame = ref.watch(savedGameProvider);
    final settings = ref.watch(settingsControllerProvider);
    final leaderboard = ref.watch(leaderboardControllerProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: HomePalette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined, color: HomePalette.mutedText),
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
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  const _Header(),
                  savedGame.when(
                    data: (saved) => saved == null ? const SizedBox.shrink() : _ResumeButton(
                          saved: saved,
                          enabled: !_navigating,
                          onTap: () => _continueGame(saved),
                        ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 28),
                  _SectionLabel(l10n.gameModeLabel),
                  const SizedBox(height: 12),
                  _LayoutSelector(
                    selected: _selectedLayout,
                    enabled: !_navigating,
                    onChanged: (layout) => setState(() => _selectedLayout = layout),
                  ),
                  const SizedBox(height: 28),
                  _SectionLabel(l10n.difficultyLevelLabel),
                  const SizedBox(height: 12),
                  _DifficultySelector(
                    selected: _selectedDifficulty,
                    enabled: !_navigating,
                    onSelected: (difficulty) {
                      setState(() => _selectedDifficulty = difficulty);
                      _startNewGame(difficulty, settings);
                    },
                  ),
                  const SizedBox(height: 28),
                  LeaderboardWidget(entries: leaderboard),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Both methods below guard on (and immediately set) `_navigating` before
  // touching the Navigator, so a double-tap - or tapping a second
  // difficulty button before the first generation finishes - can't push a
  // second GameScreen route or race a second startNewGame call. The flag
  // clears once the pushed route is popped, i.e. when the player is back on
  // Home.

  Future<void> _continueGame(GameState saved) async {
    if (_navigating) return;
    setState(() => _navigating = true);
    ref.read(gameControllerProvider.notifier).restore(saved);
    // Navigate immediately; GameScreen shows a loading spinner while the
    // puzzle is generated on a background isolate (see
    // PuzzleGenerationService), so the UI never blocks.
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const GameScreen()));
    if (mounted) setState(() => _navigating = false);
  }

  Future<void> _startNewGame(Difficulty difficulty, Settings settings) async {
    if (_navigating) return;
    setState(() => _navigating = true);
    final navigator = Navigator.of(context);
    final pushed = navigator.push(MaterialPageRoute(builder: (_) => const GameScreen()));
    await ref.read(gameControllerProvider.notifier).startNewGame(
          difficulty,
          layout: _selectedLayout,
          maxMistakes: settings.maxMistakes,
          errorLimitEnabled: settings.errorLimitEnabled,
          maxHints: settings.maxHints,
        );
    await pushed;
    if (mounted) setState(() => _navigating = false);
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            gradient: HomePalette.accentGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: HomePalette.gradientEnd.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.grid_on, color: Colors.white, size: 38),
        ),
        const SizedBox(height: 20),
        const Text(
          'Sudoku',
          style: TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: HomePalette.primaryText),
        ),
        const SizedBox(height: 6),
        const Text(
          'LOGIC · FOCUS · RELAX',
          style: TextStyle(
            fontSize: 12,
            letterSpacing: 3,
            fontWeight: FontWeight.w600,
            color: HomePalette.mutedText,
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _ResumeButton extends StatelessWidget {
  final GameState saved;
  final bool enabled;
  final VoidCallback onTap;

  const _ResumeButton({required this.saved, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: HomePalette.accentGradient,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    l10n.resumeButtonLabel(saved.difficulty.label(l10n), formatDuration(saved.elapsedSeconds)),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: HomePalette.mutedText, fontWeight: FontWeight.w600, fontSize: 14),
    );
  }
}

/// The "Spielmodus" pill-segmented control: one bordered outer pill holding
/// all [BoardLayout] options, the selected one filled with the accent
/// gradient and shown with a check mark instead of its own icon.
class _LayoutSelector extends StatelessWidget {
  final BoardLayout selected;
  final bool enabled;
  final ValueChanged<BoardLayout> onChanged;

  const _LayoutSelector({required this.selected, required this.enabled, required this.onChanged});

  static IconData _iconFor(BoardLayout layout) => switch (layout) {
        BoardLayout.classic => Icons.grid_on_outlined,
        BoardLayout.samurai => Icons.star_outline,
        BoardLayout.twin => Icons.grid_view_outlined,
        BoardLayout.gattai8 => Icons.apps_outlined,
        BoardLayout.sohei => Icons.wb_sunny_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: HomePalette.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final layout in BoardLayout.values)
            Expanded(
              child: _PillSegment(
                key: ValueKey('layout-${layout.name}'),
                isSelected: layout == selected,
                icon: _iconFor(layout),
                label: layout.label(l10n),
                onTap: enabled ? () => onChanged(layout) : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _PillSegment extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _PillSegment({super.key, required this.isSelected, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.white : HomePalette.mutedText;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? HomePalette.accentGradient : null,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? Icons.check : icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "Schwierigkeit" row: one independently-bordered pill per
/// [Difficulty], the selected one filled with the accent gradient.
class _DifficultySelector extends StatelessWidget {
  final Difficulty selected;
  final bool enabled;
  final ValueChanged<Difficulty> onSelected;

  const _DifficultySelector({required this.selected, required this.enabled, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        for (final difficulty in Difficulty.values)
          _DifficultyPill(
            key: ValueKey('difficulty-${difficulty.name}'),
            difficulty: difficulty,
            isSelected: difficulty == selected,
            label: difficulty.label(l10n),
            onTap: enabled ? () => onSelected(difficulty) : null,
          ),
      ],
    );
  }
}

class _DifficultyPill extends StatelessWidget {
  final Difficulty difficulty;
  final bool isSelected;
  final String label;
  final VoidCallback? onTap;

  const _DifficultyPill({
    super.key,
    required this.difficulty,
    required this.isSelected,
    required this.label,
    required this.onTap,
  });

  Widget _icon(Color color) {
    switch (difficulty) {
      case Difficulty.easy:
        return Icon(Icons.circle_outlined, size: 14, color: color);
      case Difficulty.medium:
        return _Dots(count: 2, color: color);
      case Difficulty.hard:
        return _Dots(count: 3, color: color);
      case Difficulty.expert:
        return Icon(Icons.grid_view_rounded, size: 14, color: color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.white : HomePalette.mutedText;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? HomePalette.accentGradient : null,
          border: isSelected ? null : Border.all(color: HomePalette.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _icon(color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final Color color;

  const _Dots({required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 3),
            child: Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ),
      ],
    );
  }
}
