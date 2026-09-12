import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/models/board_layout.dart';
import 'package:mrsudoku/models/difficulty.dart';
import 'package:mrsudoku/models/leaderboard_entry.dart';
import 'package:mrsudoku/services/leaderboard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  LeaderboardEntry entry(
    Difficulty difficulty,
    int seconds, {
    BoardLayout layout = BoardLayout.classic,
  }) =>
      LeaderboardEntry(
        difficulty: difficulty,
        layout: layout,
        elapsedSeconds: seconds,
        achievedAt: DateTime(2026, 1, 1),
      );

  test('load returns an empty list when nothing was saved yet', () async {
    expect(await const LeaderboardService().load(), isEmpty);
  });

  test('addEntry persists the entry and returns it on the next load', () async {
    const service = LeaderboardService();
    await service.addEntry(entry(Difficulty.easy, 120));

    final loaded = await service.load();
    expect(loaded, hasLength(1));
    expect(loaded.single.difficulty, Difficulty.easy);
    expect(loaded.single.elapsedSeconds, 120);
  });

  test('a difficulty group is sorted fastest-first', () async {
    const service = LeaderboardService();
    await service.addEntry(entry(Difficulty.medium, 300));
    await service.addEntry(entry(Difficulty.medium, 100));
    await service.addEntry(entry(Difficulty.medium, 200));

    final loaded = await service.load();
    expect(loaded.map((e) => e.elapsedSeconds), [100, 200, 300]);
  });

  test('different difficulties are tracked independently', () async {
    const service = LeaderboardService();
    await service.addEntry(entry(Difficulty.easy, 90));
    await service.addEntry(entry(Difficulty.expert, 900));

    final loaded = await service.load();
    expect(loaded, hasLength(2));
    expect(loaded.map((e) => e.difficulty), containsAll([Difficulty.easy, Difficulty.expert]));
  });

  test('a difficulty group is capped at maxEntriesPerDifficulty, keeping the fastest', () async {
    const service = LeaderboardService();
    for (var i = 0; i < LeaderboardService.maxEntriesPerDifficulty + 5; i++) {
      await service.addEntry(entry(Difficulty.hard, 1000 - i));
    }

    final loaded = await service.load();
    expect(loaded, hasLength(LeaderboardService.maxEntriesPerDifficulty));
    expect(loaded.first.elapsedSeconds, lessThan(loaded.last.elapsedSeconds));
    // Fastest entry is from the last iteration (i = 14 -> 1000 - 14 = 986).
    expect(loaded.first.elapsedSeconds, 1000 - (LeaderboardService.maxEntriesPerDifficulty + 5 - 1));
  });

  test('a classic and a Samurai entry at the same difficulty are tracked independently', () async {
    const service = LeaderboardService();
    await service.addEntry(entry(Difficulty.easy, 100));
    await service.addEntry(entry(Difficulty.easy, 900, layout: BoardLayout.samurai));

    final loaded = await service.load();
    expect(loaded, hasLength(2));
    expect(
      loaded.map((e) => (e.difficulty, e.layout, e.elapsedSeconds)),
      containsAll([
        (Difficulty.easy, BoardLayout.classic, 100),
        (Difficulty.easy, BoardLayout.samurai, 900),
      ]),
    );
  });

  test('fromJson falls back to BoardLayout.classic for an older entry missing the field', () {
    final json = entry(Difficulty.easy, 100).toJson()..remove('layout');
    expect(LeaderboardEntry.fromJson(json).layout, BoardLayout.classic);
  });
}
