import 'difficulty.dart';

/// One completed game recorded on the leaderboard.
class LeaderboardEntry {
  final Difficulty difficulty;
  final int elapsedSeconds;
  final DateTime achievedAt;

  const LeaderboardEntry({
    required this.difficulty,
    required this.elapsedSeconds,
    required this.achievedAt,
  });

  Map<String, dynamic> toJson() => {
        'difficulty': difficulty.name,
        'elapsedSeconds': elapsedSeconds,
        'achievedAt': achievedAt.toIso8601String(),
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
        difficulty: Difficulty.values.firstWhere((d) => d.name == json['difficulty']),
        elapsedSeconds: json['elapsedSeconds'] as int,
        achievedAt: DateTime.parse(json['achievedAt'] as String),
      );
}
