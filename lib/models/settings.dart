/// User-facing theme choice. `system` follows the OS setting.
enum AppThemeMode { system, light, dark }

/// Persisted user preferences (Einstellungsseite).
class Settings {
  final bool errorLimitEnabled;
  final int maxMistakes;
  final bool highlightEnabled;

  /// Whether wrong entries are visually marked as errors at all (section 3
  /// of the spec calls this out as separately toggleable from the mistake
  /// *limit* itself).
  final bool showErrors;
  final AppThemeMode themeMode;
  final bool soundEnabled;

  const Settings({
    this.errorLimitEnabled = true,
    this.maxMistakes = 3,
    this.highlightEnabled = true,
    this.showErrors = true,
    this.themeMode = AppThemeMode.system,
    this.soundEnabled = true,
  });

  Settings copyWith({
    bool? errorLimitEnabled,
    int? maxMistakes,
    bool? highlightEnabled,
    bool? showErrors,
    AppThemeMode? themeMode,
    bool? soundEnabled,
  }) {
    return Settings(
      errorLimitEnabled: errorLimitEnabled ?? this.errorLimitEnabled,
      maxMistakes: maxMistakes ?? this.maxMistakes,
      highlightEnabled: highlightEnabled ?? this.highlightEnabled,
      showErrors: showErrors ?? this.showErrors,
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'errorLimitEnabled': errorLimitEnabled,
        'maxMistakes': maxMistakes,
        'highlightEnabled': highlightEnabled,
        'showErrors': showErrors,
        'themeMode': themeMode.name,
        'soundEnabled': soundEnabled,
      };

  factory Settings.fromJson(Map<String, dynamic> json) => Settings(
        errorLimitEnabled: json['errorLimitEnabled'] as bool? ?? true,
        maxMistakes: json['maxMistakes'] as int? ?? 3,
        highlightEnabled: json['highlightEnabled'] as bool? ?? true,
        showErrors: json['showErrors'] as bool? ?? true,
        themeMode: AppThemeMode.values.firstWhere(
          (m) => m.name == json['themeMode'],
          orElse: () => AppThemeMode.system,
        ),
        soundEnabled: json['soundEnabled'] as bool? ?? true,
      );
}
