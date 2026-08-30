/// User-facing theme choice. `system` follows the OS setting.
enum AppThemeMode { system, light, dark }

/// Persisted user preferences (Einstellungsseite).
class Settings {
  final bool errorLimitEnabled;
  final int maxMistakes;
  final bool highlightEnabled;
  final AppThemeMode themeMode;
  final bool soundEnabled;

  const Settings({
    this.errorLimitEnabled = true,
    this.maxMistakes = 3,
    this.highlightEnabled = true,
    this.themeMode = AppThemeMode.system,
    this.soundEnabled = true,
  });

  Settings copyWith({
    bool? errorLimitEnabled,
    int? maxMistakes,
    bool? highlightEnabled,
    AppThemeMode? themeMode,
    bool? soundEnabled,
  }) {
    return Settings(
      errorLimitEnabled: errorLimitEnabled ?? this.errorLimitEnabled,
      maxMistakes: maxMistakes ?? this.maxMistakes,
      highlightEnabled: highlightEnabled ?? this.highlightEnabled,
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'errorLimitEnabled': errorLimitEnabled,
        'maxMistakes': maxMistakes,
        'highlightEnabled': highlightEnabled,
        'themeMode': themeMode.name,
        'soundEnabled': soundEnabled,
      };

  factory Settings.fromJson(Map<String, dynamic> json) => Settings(
        errorLimitEnabled: json['errorLimitEnabled'] as bool? ?? true,
        maxMistakes: json['maxMistakes'] as int? ?? 3,
        highlightEnabled: json['highlightEnabled'] as bool? ?? true,
        themeMode: AppThemeMode.values.firstWhere(
          (m) => m.name == json['themeMode'],
          orElse: () => AppThemeMode.system,
        ),
        soundEnabled: json['soundEnabled'] as bool? ?? true,
      );
}
