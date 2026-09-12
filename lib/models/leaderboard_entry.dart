import 'board_layout.dart';
import 'difficulty.dart';

/// One completed game recorded on the leaderboard.
class LeaderboardEntry {
  final Difficulty difficulty;
  final BoardLayout layout;
  final int elapsedSeconds;
  final DateTime achievedAt;

  const LeaderboardEntry({
    required this.difficulty,
    this.layout = BoardLayout.classic,
    required this.elapsedSeconds,
    required this.achievedAt,
  });

  Map<String, dynamic> toJson() => {
        'difficulty': difficulty.name,
        'layout': layout.name,
        'elapsedSeconds': elapsedSeconds,
        'achievedAt': achievedAt.toIso8601String(),
      };

  /// `layout` defaults to classic for an older entry saved before Samurai
  /// existed, so past leaderboard data isn't discarded.
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        difficulty: Difficulty.values.firstWhere((d) => d.name == json['difficulty']),
        layout: BoardLayout.values.firstWhere(
          (l) => l.name == json['layout'],
          orElse: () => BoardLayout.classic,
        ),
        elapsedSeconds: json['elapsedSeconds'] as int,
        achievedAt: DateTime.parse(json['achievedAt'] as String),
      );
}
