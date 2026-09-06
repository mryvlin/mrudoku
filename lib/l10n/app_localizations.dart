import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// Settings screen title and the gear icon's tooltip.
  ///
  /// In de, this message translates to:
  /// **'Einstellungen'**
  String get settings;

  /// Generic 'resume' word, used both as the pause-toggle tooltip and inside resumeButtonLabel.
  ///
  /// In de, this message translates to:
  /// **'Fortsetzen'**
  String get resume;

  /// Home screen button offering to continue a saved game.
  ///
  /// In de, this message translates to:
  /// **'Fortsetzen - {difficulty} ({time})'**
  String resumeButtonLabel(String difficulty, String time);

  /// Heading above the difficulty buttons on the Home screen.
  ///
  /// In de, this message translates to:
  /// **'Neues Spiel'**
  String get newGame;

  /// Tooltip for the pause button while the game is running.
  ///
  /// In de, this message translates to:
  /// **'Pausieren'**
  String get pause;

  /// Game screen AppBar title.
  ///
  /// In de, this message translates to:
  /// **'Sudoku - {difficulty}'**
  String gameTitle(String difficulty);

  /// Title of the dialog shown when the puzzle is solved.
  ///
  /// In de, this message translates to:
  /// **'Geschafft! 🎉'**
  String get wonTitle;

  /// Body of the win dialog.
  ///
  /// In de, this message translates to:
  /// **'Du hast das Rätsel in {time} gelöst.'**
  String wonMessage(String time);

  /// Title of the dialog shown when the mistake limit is reached.
  ///
  /// In de, this message translates to:
  /// **'Game Over'**
  String get gameOverTitle;

  /// Body of the game-over dialog.
  ///
  /// In de, this message translates to:
  /// **'Du hast das Fehlerlimit erreicht.'**
  String get gameOverMessage;

  /// Button on the win/game-over dialogs that returns to the Home screen.
  ///
  /// In de, this message translates to:
  /// **'Zum Menü'**
  String get backToMenu;

  /// Label shown on the paused-game overlay.
  ///
  /// In de, this message translates to:
  /// **'Pausiert'**
  String get paused;

  /// Settings switch title.
  ///
  /// In de, this message translates to:
  /// **'Fehlerlimit aktiv'**
  String get errorLimitTitle;

  /// Settings switch subtitle.
  ///
  /// In de, this message translates to:
  /// **'Spiel endet nach zu vielen Fehlern'**
  String get errorLimitSubtitle;

  /// Label above the max-mistakes slider.
  ///
  /// In de, this message translates to:
  /// **'Maximale Fehler'**
  String get maxMistakesTitle;

  /// Settings switch title.
  ///
  /// In de, this message translates to:
  /// **'Falsche Zahlen anzeigen'**
  String get showErrorsTitle;

  /// Settings switch subtitle.
  ///
  /// In de, this message translates to:
  /// **'Markiert falsch eingetragene Zahlen farblich'**
  String get showErrorsSubtitle;

  /// Settings switch title.
  ///
  /// In de, this message translates to:
  /// **'Hervorhebungen'**
  String get highlightsTitle;

  /// Settings switch subtitle.
  ///
  /// In de, this message translates to:
  /// **'Zeile/Spalte/Box und gleiche Zahlen farblich markieren'**
  String get highlightsSubtitle;

  /// Title above the highlight-color swatch picker.
  ///
  /// In de, this message translates to:
  /// **'Hervorhebungsfarbe'**
  String get highlightColorTitle;

  /// Settings switch title.
  ///
  /// In de, this message translates to:
  /// **'Sound'**
  String get soundTitle;

  /// Settings switch subtitle.
  ///
  /// In de, this message translates to:
  /// **'Feedback-Töne und Vibration bei Eingaben'**
  String get soundSubtitle;

  /// Heading above the theme radio group.
  ///
  /// In de, this message translates to:
  /// **'Design'**
  String get designHeading;

  /// Theme option: follow the OS setting.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Theme option: always light.
  ///
  /// In de, this message translates to:
  /// **'Hell'**
  String get themeLight;

  /// Theme option: always dark.
  ///
  /// In de, this message translates to:
  /// **'Dunkel'**
  String get themeDark;

  /// Heading above the language radio group.
  ///
  /// In de, this message translates to:
  /// **'Sprache'**
  String get languageHeading;

  /// Language option: follow the OS setting.
  ///
  /// In de, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// Language option: always German.
  ///
  /// In de, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// Language option: always English.
  ///
  /// In de, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Highlight color name.
  ///
  /// In de, this message translates to:
  /// **'Rot'**
  String get highlightColorRed;

  /// Highlight color name.
  ///
  /// In de, this message translates to:
  /// **'Orange'**
  String get highlightColorOrange;

  /// Highlight color name.
  ///
  /// In de, this message translates to:
  /// **'Grün'**
  String get highlightColorGreen;

  /// Highlight color name.
  ///
  /// In de, this message translates to:
  /// **'Blau'**
  String get highlightColorBlue;

  /// Highlight color name.
  ///
  /// In de, this message translates to:
  /// **'Lila'**
  String get highlightColorPurple;

  /// Highlight color name.
  ///
  /// In de, this message translates to:
  /// **'Türkis'**
  String get highlightColorTeal;

  /// Difficulty level name.
  ///
  /// In de, this message translates to:
  /// **'Einfach'**
  String get difficultyEasy;

  /// Difficulty level name.
  ///
  /// In de, this message translates to:
  /// **'Mittel'**
  String get difficultyMedium;

  /// Difficulty level name.
  ///
  /// In de, this message translates to:
  /// **'Schwer'**
  String get difficultyHard;

  /// Difficulty level name.
  ///
  /// In de, this message translates to:
  /// **'Experte'**
  String get difficultyExpert;

  /// Toolbar button label.
  ///
  /// In de, this message translates to:
  /// **'Rückgängig'**
  String get undoLabel;

  /// Toolbar button label.
  ///
  /// In de, this message translates to:
  /// **'Wiederholen'**
  String get redoLabel;

  /// Toolbar button label (notes-mode toggle).
  ///
  /// In de, this message translates to:
  /// **'Notizen'**
  String get notesLabel;

  /// Toolbar button label (auto-fill notes).
  ///
  /// In de, this message translates to:
  /// **'Auto-Notizen'**
  String get autoNotesLabel;

  /// Toolbar button label showing remaining hints.
  ///
  /// In de, this message translates to:
  /// **'Hinweis ({count})'**
  String hintLabel(int count);

  /// Heading of the best-times card on the Home screen.
  ///
  /// In de, this message translates to:
  /// **'Bestenliste'**
  String get leaderboardTitle;

  /// Hint explanation for a naked single.
  ///
  /// In de, this message translates to:
  /// **'Zeile {row}, Spalte {col} hat nur einen möglichen Kandidaten: {value}.'**
  String hintNakedSingle(int row, int col, int value);

  /// Hint explanation for a hidden single. {unit} is one of unitRow/unitColumn/unitBox, already formatted.
  ///
  /// In de, this message translates to:
  /// **'In {unit} kann die {value} nur noch in Zeile {row}, Spalte {col} stehen.'**
  String hintHiddenSingle(String unit, int value, int row, int col);

  /// A row, by 1-based index, used inside hintHiddenSingle.
  ///
  /// In de, this message translates to:
  /// **'Zeile {n}'**
  String unitRow(int n);

  /// A column, by 1-based index, used inside hintHiddenSingle.
  ///
  /// In de, this message translates to:
  /// **'Spalte {n}'**
  String unitColumn(int n);

  /// A 3x3 box, by 1-based index, used inside hintHiddenSingle.
  ///
  /// In de, this message translates to:
  /// **'Box {n}'**
  String unitBox(int n);

  /// Lead-in sentence prepended to the base hint explanation.
  ///
  /// In de, this message translates to:
  /// **'Nach Ausschluss durch ein Paar-Muster (Naked Pair / Pointing Pair / Box-Line Reduction):'**
  String get leadInPairElimination;

  /// Lead-in sentence prepended to the base hint explanation.
  ///
  /// In de, this message translates to:
  /// **'Nach Ausschluss durch ein verstecktes Paar:'**
  String get leadInHiddenPair;

  /// Lead-in sentence prepended to the base hint explanation.
  ///
  /// In de, this message translates to:
  /// **'Nach Ausschluss durch ein Kandidaten-Trio:'**
  String get leadInNakedTriple;

  /// Lead-in sentence prepended to the base hint explanation.
  ///
  /// In de, this message translates to:
  /// **'Nach Ausschluss durch ein X-Wing-Muster:'**
  String get leadInXWing;

  /// Solving technique name shown before the hint explanation.
  ///
  /// In de, this message translates to:
  /// **'Naked Single'**
  String get techniqueNakedSingle;

  /// Solving technique name shown before the hint explanation.
  ///
  /// In de, this message translates to:
  /// **'Hidden Single'**
  String get techniqueHiddenSingle;

  /// Solving technique name shown before the hint explanation.
  ///
  /// In de, this message translates to:
  /// **'Kandidaten-Ausschluss (Naked Pair / Pointing Pair / Box-Line Reduction)'**
  String get techniquePairElimination;

  /// Solving technique name shown before the hint explanation.
  ///
  /// In de, this message translates to:
  /// **'Verstecktes Paar (Hidden Pair)'**
  String get techniqueHiddenPair;

  /// Solving technique name shown before the hint explanation.
  ///
  /// In de, this message translates to:
  /// **'Kandidaten-Trio (Naked Triple)'**
  String get techniqueNakedTriple;

  /// Solving technique name shown before the hint explanation.
  ///
  /// In de, this message translates to:
  /// **'X-Wing'**
  String get techniqueXWing;

  /// Solving technique name for the direct-reveal fallback hint.
  ///
  /// In de, this message translates to:
  /// **'Rückwärtssuche (Ausprobieren)'**
  String get techniqueBacktracking;

  /// Hint message shown when no logical technique applies and the solution is revealed directly.
  ///
  /// In de, this message translates to:
  /// **'Keine einfache Logik-Regel greift hier - die Lösung für diese Zelle wird direkt verraten.'**
  String get hintDirectReveal;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
