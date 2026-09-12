// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get resume => 'Resume';

  @override
  String get hintDismiss => 'Got it';

  @override
  String resumeButtonLabel(String difficulty, String time) {
    return 'Resume - $difficulty ($time)';
  }

  @override
  String get newGame => 'New Game';

  @override
  String get pause => 'Pause';

  @override
  String gameTitle(String difficulty) {
    return 'Sudoku - $difficulty';
  }

  @override
  String get wonTitle => 'Solved! 🎉';

  @override
  String wonMessage(String time) {
    return 'You solved the puzzle in $time.';
  }

  @override
  String get gameOverTitle => 'Game Over';

  @override
  String get gameOverMessage => 'You reached the mistake limit.';

  @override
  String get backToMenu => 'Back to Menu';

  @override
  String get paused => 'Paused';

  @override
  String get errorLimitTitle => 'Mistake limit active';

  @override
  String get errorLimitSubtitle => 'Game ends after too many mistakes';

  @override
  String get maxMistakesTitle => 'Maximum mistakes';

  @override
  String get maxHintsTitle => 'Maximum hints';

  @override
  String get showErrorsTitle => 'Show wrong numbers';

  @override
  String get showErrorsSubtitle => 'Marks incorrectly entered numbers in color';

  @override
  String get highlightsTitle => 'Highlights';

  @override
  String get highlightsSubtitle =>
      'Color-highlight the row/column/box and matching numbers';

  @override
  String get highlightColorTitle => 'Highlight color';

  @override
  String get soundTitle => 'Sound';

  @override
  String get soundSubtitle => 'Feedback tones and vibration on input';

  @override
  String get designHeading => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageHeading => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get languageEnglish => 'English';

  @override
  String get highlightColorRed => 'Red';

  @override
  String get highlightColorOrange => 'Orange';

  @override
  String get highlightColorGreen => 'Green';

  @override
  String get highlightColorBlue => 'Blue';

  @override
  String get highlightColorPurple => 'Purple';

  @override
  String get highlightColorTeal => 'Teal';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get difficultyExpert => 'Expert';

  @override
  String get undoLabel => 'Undo';

  @override
  String get redoLabel => 'Redo';

  @override
  String get notesLabel => 'Notes';

  @override
  String get autoNotesLabel => 'Auto-Notes';

  @override
  String get autoSolveLabel => 'Auto-Solve';

  @override
  String hintLabel(int count) {
    return 'Hint ($count)';
  }

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String hintNakedSingle(int row, int col, int value) {
    return 'Row $row, column $col has only one possible candidate: $value.';
  }

  @override
  String hintHiddenSingle(String unit, int value, int row, int col) {
    return 'In $unit, $value can only go in row $row, column $col.';
  }

  @override
  String unitRow(int n) {
    return 'row $n';
  }

  @override
  String unitColumn(int n) {
    return 'column $n';
  }

  @override
  String unitBox(int n) {
    return 'box $n';
  }

  @override
  String get leadInPairElimination =>
      'After elimination via a pair pattern (naked pair / pointing pair / box-line reduction):';

  @override
  String get leadInHiddenPair => 'After elimination via a hidden pair:';

  @override
  String get leadInNakedTriple => 'After elimination via a candidate triple:';

  @override
  String get leadInXWing => 'After elimination via an X-Wing pattern:';

  @override
  String get leadInXYWing => 'After elimination via an XY-Wing pattern:';

  @override
  String get leadInSwordfish => 'After elimination via a Swordfish pattern:';

  @override
  String get techniqueNakedSingle => 'Naked Single';

  @override
  String get techniqueHiddenSingle => 'Hidden Single';

  @override
  String get techniquePairElimination =>
      'Candidate elimination (naked pair / pointing pair / box-line reduction)';

  @override
  String get techniqueHiddenPair => 'Hidden pair';

  @override
  String get techniqueNakedTriple => 'Naked triple';

  @override
  String get techniqueXWing => 'X-Wing';

  @override
  String get techniqueXYWing => 'XY-Wing';

  @override
  String get techniqueSwordfish => 'Swordfish';

  @override
  String get techniqueBacktracking => 'Backtracking (trial and error)';

  @override
  String get hintDirectReveal =>
      'No simple logical rule applies here - the solution for this cell is revealed directly.';
}
