import '../l10n/app_localizations.dart';
import '../models/difficulty.dart';

/// Localized display name for a [Difficulty]. Kept in the UI layer (like
/// `HighlightColorX.label` in `highlight_colors.dart`) so `models/` stays
/// free of Flutter/localization imports.
extension DifficultyLabelX on Difficulty {
  String label(AppLocalizations l10n) {
    switch (this) {
      case Difficulty.easy:
        return l10n.difficultyEasy;
      case Difficulty.medium:
        return l10n.difficultyMedium;
      case Difficulty.hard:
        return l10n.difficultyHard;
      case Difficulty.expert:
        return l10n.difficultyExpert;
    }
  }
}
