import 'package:flutter/material.dart';

import '../../models/difficulty.dart';
import '../../models/leaderboard_entry.dart';
import '../format_duration.dart';

/// Best-times board shown on the Home screen: for every difficulty that has
/// at least one completed game, lists its fastest times (already sorted and
/// capped by [LeaderboardService]).
class LeaderboardWidget extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  /// Max rows shown per difficulty, to keep the Home screen compact.
  static const _rowsPerDifficulty = 3;

  const LeaderboardWidget({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final byDifficulty = <Difficulty, List<LeaderboardEntry>>{};
    for (final entry in entries) {
      byDifficulty.putIfAbsent(entry.difficulty, () => []).add(entry);
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Bestenliste', style: theme.textTheme.titleMedium),
              ],
            ),
            for (final difficulty in Difficulty.values)
              if (byDifficulty[difficulty] case final difficultyEntries?)
                _DifficultySection(
                  difficulty: difficulty,
                  entries: (difficultyEntries..sort((a, b) => a.elapsedSeconds.compareTo(b.elapsedSeconds)))
                      .take(_rowsPerDifficulty)
                      .toList(),
                ),
          ],
        ),
      ),
    );
  }
}

class _DifficultySection extends StatelessWidget {
  final Difficulty difficulty;
  final List<LeaderboardEntry> entries;

  const _DifficultySection({required this.difficulty, required this.entries});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            difficulty.label,
            style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
          ),
          for (var i = 0; i < entries.length; i++)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text('${i + 1}.', style: theme.textTheme.bodyMedium),
                  ),
                  Text(formatDuration(entries[i].elapsedSeconds), style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
