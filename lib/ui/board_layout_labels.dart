import '../l10n/app_localizations.dart';
import '../models/board_layout.dart';

/// Localized display name for a [BoardLayout]. Kept in the UI layer (like
/// `DifficultyLabelX.label` in `difficulty_labels.dart`) so `models/` stays
/// free of Flutter/localization imports.
extension BoardLayoutLabelX on BoardLayout {
  String label(AppLocalizations l10n) {
    switch (this) {
      case BoardLayout.classic:
        return l10n.boardLayoutClassic;
      case BoardLayout.samurai:
        return l10n.boardLayoutSamurai;
      case BoardLayout.twin:
        return l10n.boardLayoutTwin;
      case BoardLayout.gattai8:
        return l10n.boardLayoutGattai8;
      case BoardLayout.sohei:
        return l10n.boardLayoutSohei;
    }
  }
}
