import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/difficulty.dart';
import '../models/leaderboard_entry.dart';

/// Persists completed-game times locally via `shared_preferences`, grouped
/// and ranked by [Difficulty].
class LeaderboardService {
  static const _key = 'mrsudoku.leaderboard';

  /// Fastest entries kept per difficulty, so the saved list can't grow
  /// without bound.
  static const maxEntriesPerDifficulty = 10;

  const LeaderboardService();

  Future<List<LeaderboardEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Adds [entry], re-sorts its difficulty group by time (fastest first) and
  /// trims it to [maxEntriesPerDifficulty]. Returns the full updated list.
  Future<List<LeaderboardEntry>> addEntry(LeaderboardEntry entry) async {
    final current = await load();
    final byDifficulty = <Difficulty, List<LeaderboardEntry>>{};
    for (final e in current) {
      byDifficulty.putIfAbsent(e.difficulty, () => []).add(e);
    }
    byDifficulty.putIfAbsent(entry.difficulty, () => []).add(entry);

    final result = <LeaderboardEntry>[];
    for (final entries in byDifficulty.values) {
      entries.sort((a, b) => a.elapsedSeconds.compareTo(b.elapsedSeconds));
      result.addAll(entries.take(maxEntriesPerDifficulty));
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(result.map((e) => e.toJson()).toList()));
    return result;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
