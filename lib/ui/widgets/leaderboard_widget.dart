import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/board_layout.dart';
import '../../models/difficulty.dart';
import '../../models/leaderboard_entry.dart';
import '../board_layout_labels.dart';
import '../difficulty_labels.dart';
import '../format_duration.dart';
import '../home_palette.dart';

/// Best-times board shown on the Home screen: for every difficulty (and
/// layout) that has at least one completed game, lists its fastest times
/// (already sorted and capped by [LeaderboardService]). Styled with the
/// same fixed dark [HomePalette] as the rest of Home, not the app theme.
class LeaderboardWidget extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  /// Max rows shown per difficulty, to keep the Home screen compact.
  static const _rowsPerDifficulty = 3;

  const LeaderboardWidget({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final byGroup = <(Difficulty, BoardLayout), List<LeaderboardEntry>>{};
    for (final entry in entries) {
      byGroup.putIfAbsent((entry.difficulty, entry.layout), () => []).add(entry);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HomePalette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: HomePalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined, color: HomePalette.primaryText),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.leaderboardTitle,
                style: const TextStyle(color: HomePalette.primaryText, fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ],
          ),
          for (final layout in BoardLayout.values)
            for (final difficulty in Difficulty.values)
              if (byGroup[(difficulty, layout)] case final groupEntries?)
                _DifficultySection(
                  difficulty: difficulty,
                  layout: layout,
                  entries: (groupEntries..sort((a, b) => a.elapsedSeconds.compareTo(b.elapsedSeconds)))
                      .take(_rowsPerDifficulty)
                      .toList(),
                ),
        ],
      ),
    );
  }
}

class _DifficultySection extends StatelessWidget {
  final Difficulty difficulty;
  final BoardLayout layout;
  final List<LeaderboardEntry> entries;

  const _DifficultySection({required this.difficulty, required this.layout, required this.entries});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Classic keeps its plain difficulty label unchanged; only a
    // non-classic layout gets an extra suffix, so today's leaderboard
    // display doesn't change at all until a Samurai game is won.
    final title = layout == BoardLayout.classic
        ? difficulty.label(l10n)
        : '${difficulty.label(l10n)} (${layout.label(l10n)})';
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: HomePalette.mutedText, fontWeight: FontWeight.w700, fontSize: 12),
          ),
          for (var i = 0; i < entries.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${i + 1}.',
                      style: const TextStyle(color: HomePalette.mutedText, fontSize: 13),
                    ),
                  ),
                  if (i == 0) ...[
                    const Icon(Icons.emoji_events, color: HomePalette.gold, size: 14),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    formatDuration(entries[i].elapsedSeconds),
                    style: TextStyle(
                      color: i == 0 ? HomePalette.gold : HomePalette.primaryText,
                      fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
