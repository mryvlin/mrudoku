// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get settings => 'Einstellungen';

  @override
  String get resume => 'Fortsetzen';

  @override
  String get hintDismiss => 'Verstanden';

  @override
  String resumeButtonLabel(String difficulty, String time) {
    return 'Fortsetzen - $difficulty ($time)';
  }

  @override
  String get newGame => 'Neues Spiel';

  @override
  String get pause => 'Pausieren';

  @override
  String gameTitle(String difficulty) {
    return 'Sudoku - $difficulty';
  }

  @override
  String get wonTitle => 'Geschafft! 🎉';

  @override
  String wonMessage(String time) {
    return 'Du hast das Rätsel in $time gelöst.';
  }

  @override
  String get gameOverTitle => 'Game Over';

  @override
  String get gameOverMessage => 'Du hast das Fehlerlimit erreicht.';

  @override
  String get backToMenu => 'Zum Menü';

  @override
  String get paused => 'Pausiert';

  @override
  String get errorLimitTitle => 'Fehlerlimit aktiv';

  @override
  String get errorLimitSubtitle => 'Spiel endet nach zu vielen Fehlern';

  @override
  String get maxMistakesTitle => 'Maximale Fehler';

  @override
  String get maxHintsTitle => 'Maximale Hinweise';

  @override
  String get showErrorsTitle => 'Falsche Zahlen anzeigen';

  @override
  String get showErrorsSubtitle =>
      'Markiert falsch eingetragene Zahlen farblich';

  @override
  String get highlightsTitle => 'Hervorhebungen';

  @override
  String get highlightsSubtitle =>
      'Zeile/Spalte/Box und gleiche Zahlen farblich markieren';

  @override
  String get highlightColorTitle => 'Hervorhebungsfarbe';

  @override
  String get soundTitle => 'Sound';

  @override
  String get soundSubtitle => 'Feedback-Töne und Vibration bei Eingaben';

  @override
  String get designHeading => 'Design';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get languageHeading => 'Sprache';

  @override
  String get languageSystem => 'System';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get highlightColorRed => 'Rot';

  @override
  String get highlightColorOrange => 'Orange';

  @override
  String get highlightColorGreen => 'Grün';

  @override
  String get highlightColorBlue => 'Blau';

  @override
  String get highlightColorPurple => 'Lila';

  @override
  String get highlightColorTeal => 'Türkis';

  @override
  String get difficultyEasy => 'Einfach';

  @override
  String get difficultyMedium => 'Mittel';

  @override
  String get difficultyHard => 'Schwer';

  @override
  String get difficultyExpert => 'Experte';

  @override
  String get undoLabel => 'Rückgängig';

  @override
  String get redoLabel => 'Wiederholen';

  @override
  String get notesLabel => 'Notizen';

  @override
  String get autoNotesLabel => 'Auto-Notizen';

  @override
  String hintLabel(int count) {
    return 'Hinweis ($count)';
  }

  @override
  String get leaderboardTitle => 'Bestenliste';

  @override
  String hintNakedSingle(int row, int col, int value) {
    return 'Zeile $row, Spalte $col hat nur einen möglichen Kandidaten: $value.';
  }

  @override
  String hintHiddenSingle(String unit, int value, int row, int col) {
    return 'In $unit kann die $value nur noch in Zeile $row, Spalte $col stehen.';
  }

  @override
  String unitRow(int n) {
    return 'Zeile $n';
  }

  @override
  String unitColumn(int n) {
    return 'Spalte $n';
  }

  @override
  String unitBox(int n) {
    return 'Box $n';
  }

  @override
  String get leadInPairElimination =>
      'Nach Ausschluss durch ein Paar-Muster (Naked Pair / Pointing Pair / Box-Line Reduction):';

  @override
  String get leadInHiddenPair => 'Nach Ausschluss durch ein verstecktes Paar:';

  @override
  String get leadInNakedTriple => 'Nach Ausschluss durch ein Kandidaten-Trio:';

  @override
  String get leadInXWing => 'Nach Ausschluss durch ein X-Wing-Muster:';

  @override
  String get techniqueNakedSingle => 'Naked Single';

  @override
  String get techniqueHiddenSingle => 'Hidden Single';

  @override
  String get techniquePairElimination =>
      'Kandidaten-Ausschluss (Naked Pair / Pointing Pair / Box-Line Reduction)';

  @override
  String get techniqueHiddenPair => 'Verstecktes Paar (Hidden Pair)';

  @override
  String get techniqueNakedTriple => 'Kandidaten-Trio (Naked Triple)';

  @override
  String get techniqueXWing => 'X-Wing';

  @override
  String get techniqueBacktracking => 'Rückwärtssuche (Ausprobieren)';

  @override
  String get hintDirectReveal =>
      'Keine einfache Logik-Regel greift hier - die Lösung für diese Zelle wird direkt verraten.';
}
