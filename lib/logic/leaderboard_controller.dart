import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';
import 'service_providers.dart';

/// Loads the leaderboard on startup and appends new entries as games are won
/// (see [GameController.inputNumber]/[GameController.useHint]).
class LeaderboardController extends Notifier<List<LeaderboardEntry>> {
  LeaderboardService get _service => ref.read(leaderboardServiceProvider);

  @override
  List<LeaderboardEntry> build() {
    _load();
    return const [];
  }

  Future<void> _load() async => state = await _service.load();

  Future<void> addEntry(LeaderboardEntry entry) async {
    state = await _service.addEntry(entry);
  }
}

final leaderboardControllerProvider =
    NotifierProvider<LeaderboardController, List<LeaderboardEntry>>(LeaderboardController.new);
