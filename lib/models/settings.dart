/// User-facing theme choice. `system` follows the OS setting.
enum AppThemeMode { system, light, dark }

/// Selectable accent color for selection/peer/same-value highlighting on the
/// board. The actual paint color (which shifts shade for dark mode) is
/// resolved in the UI layer - see `HighlightColorX` in
/// `ui/highlight_colors.dart` - so this model stays free of Flutter imports.
enum HighlightColor { red, orange, green, blue, purple, teal }

extension HighlightColorX on HighlightColor {
  String get label {
    switch (this) {
      case HighlightColor.red:
        return 'Rot';
      case HighlightColor.orange:
        return 'Orange';
      case HighlightColor.green:
        return 'Grün';
      case HighlightColor.blue:
        return 'Blau';
      case HighlightColor.purple:
        return 'Lila';
      case HighlightColor.teal:
        return 'Türkis';
    }
  }
}

/// Persisted user preferences (Einstellungsseite).
class Settings {
  final bool errorLimitEnabled;
  final int maxMistakes;
  final bool highlightEnabled;
  final HighlightColor highlightColor;

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
    this.highlightColor = HighlightColor.red,
    this.showErrors = true,
    this.themeMode = AppThemeMode.system,
    this.soundEnabled = true,
  });

  Settings copyWith({
    bool? errorLimitEnabled,
    int? maxMistakes,
    bool? highlightEnabled,
    HighlightColor? highlightColor,
    bool? showErrors,
    AppThemeMode? themeMode,
    bool? soundEnabled,
  }) {
    return Settings(
      errorLimitEnabled: errorLimitEnabled ?? this.errorLimitEnabled,
      maxMistakes: maxMistakes ?? this.maxMistakes,
      highlightEnabled: highlightEnabled ?? this.highlightEnabled,
      highlightColor: highlightColor ?? this.highlightColor,
      showErrors: showErrors ?? this.showErrors,
      themeMode: themeMode ?? this.themeMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'errorLimitEnabled': errorLimitEnabled,
        'maxMistakes': maxMistakes,
        'highlightEnabled': highlightEnabled,
        'highlightColor': highlightColor.name,
        'showErrors': showErrors,
        'themeMode': themeMode.name,
        'soundEnabled': soundEnabled,
      };

  factory Settings.fromJson(Map<String, dynamic> json) => Settings(
        errorLimitEnabled: json['errorLimitEnabled'] as bool? ?? true,
        maxMistakes: json['maxMistakes'] as int? ?? 3,
        highlightEnabled: json['highlightEnabled'] as bool? ?? true,
        highlightColor: HighlightColor.values.firstWhere(
          (c) => c.name == json['highlightColor'],
          orElse: () => HighlightColor.red,
        ),
        showErrors: json['showErrors'] as bool? ?? true,
        themeMode: AppThemeMode.values.firstWhere(
          (m) => m.name == json['themeMode'],
          orElse: () => AppThemeMode.system,
        ),
        soundEnabled: json['soundEnabled'] as bool? ?? true,
      );
}
