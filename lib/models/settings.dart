/// User-facing theme choice. `system` follows the OS setting.
enum AppThemeMode { system, light, dark }

/// User-facing language choice. `system` follows the OS locale (falling back
/// to German if the OS locale isn't supported - see `supportedLocales` in
/// main.dart).
enum AppLocale { system, de, en }

/// Selectable accent color for selection/peer/same-value highlighting on the
/// board. The actual paint color (which shifts shade for dark mode) and the
/// localized display name are resolved in the UI layer - see
/// `HighlightColorX` in `ui/highlight_colors.dart` - so this model stays free
/// of Flutter imports.
enum HighlightColor { red, orange, green, blue, purple, teal }

/// Persisted user preferences (Einstellungsseite).
class Settings {
  final bool errorLimitEnabled;
  final int maxMistakes;
  final int maxHints;
  final bool highlightEnabled;
  final HighlightColor highlightColor;

  /// Whether wrong entries are visually marked as errors at all (section 3
  /// of the spec calls this out as separately toggleable from the mistake
  /// *limit* itself).
  final bool showErrors;
  final AppThemeMode themeMode;
  final AppLocale locale;
  final bool soundEnabled;

  const Settings({
    this.errorLimitEnabled = true,
    this.maxMistakes = 3,
    this.maxHints = 5,
    this.highlightEnabled = true,
    this.highlightColor = HighlightColor.red,
    this.showErrors = true,
    this.themeMode = AppThemeMode.system,
    this.locale = AppLocale.system,
    this.soundEnabled = true,
  });

  Settings copyWith({
    bool? errorLimitEnabled,
    int? maxMistakes,
    int? maxHints,
    bool? highlightEnabled,
    HighlightColor? highlightColor,
    bool? showErrors,
    AppThemeMode? themeMode,
    AppLocale? locale,
    bool? soundEnabled,
  }) {
    return Settings(
      errorLimitEnabled: errorLimitEnabled ?? this.errorLimitEnabled,
      maxMistakes: maxMistakes ?? this.maxMistakes,
      maxHints: maxHints ?? this.maxHints,
      highlightEnabled: highlightEnabled ?? this.highlightEnabled,
      highlightColor: highlightColor ?? this.highlightColor,
      showErrors: showErrors ?? this.showErrors,
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'errorLimitEnabled': errorLimitEnabled,
        'maxMistakes': maxMistakes,
        'maxHints': maxHints,
        'highlightEnabled': highlightEnabled,
        'highlightColor': highlightColor.name,
        'showErrors': showErrors,
        'themeMode': themeMode.name,
        'locale': locale.name,
        'soundEnabled': soundEnabled,
      };

  factory Settings.fromJson(Map<String, dynamic> json) => Settings(
        errorLimitEnabled: json['errorLimitEnabled'] as bool? ?? true,
        maxMistakes: json['maxMistakes'] as int? ?? 3,
        maxHints: json['maxHints'] as int? ?? 5,
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
        locale: AppLocale.values.firstWhere(
          (l) => l.name == json['locale'],
          orElse: () => AppLocale.system,
        ),
        soundEnabled: json['soundEnabled'] as bool? ?? true,
      );
}
