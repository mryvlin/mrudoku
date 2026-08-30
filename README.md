# mrsudoku

Ein vollständiges, produktionsreifes Sudoku-Spiel als Flutter-App - lauffähig
als Android-App und als Web-App (Flutter Web). Komplett offline, keine
Cloud-Abhängigkeit.

## Architektur

Die Kern-UI (Raster, Zahleneingabe, Nummernpad) ist mit normalen
Flutter-Widgets umgesetzt statt mit einer reinen Flame-Canvas-Lösung - für ein
rasterbasiertes Puzzle ist das robuster, einfacher zugänglich (Screenreader,
Touch-Ziele, Layout) und leichter zu warten. Flame kommt gezielt dort zum
Einsatz, wo es echten Mehrwert bringt: der Konfetti-Partikeleffekt beim Lösen
des Rätsels (`lib/ui/widgets/win_celebration.dart`).

Als State-Management-Lösung kommt **Riverpod** (`flutter_riverpod`, moderne
`Notifier`/`NotifierProvider`-API) zum Einsatz: Spiellogik lässt sich darüber
unabhängig von Flutter-Widgets testen (siehe `test/logic/game_controller_test.dart`,
das den Controller über einen `ProviderContainer` ganz ohne Widget-Baum
durchspielt), Abhängigkeiten (Persistenz, Sound) werden sauber injiziert statt
global referenziert, und die reaktive Aktualisierung von Board, Timer und
Einstellungen ist ohne manuelles `setState`-Jonglieren möglich.

### Projektstruktur

```
lib/
  models/     Reines Dart, keine Flutter-Imports: Cell, Board, Difficulty,
              Settings, GameState. Unveränderlich (immutable), JSON-
              serialisierbar für die Persistenz.
  logic/      Reines Dart: Solver (Backtracking + Eindeutigkeitsprüfung),
              Generator (erzeugt Rätsel mit eindeutiger Lösung), HintEngine
              (Naked/Hidden Single, Naked/Pointing Pair - Basis für
              Hinweise und Schwierigkeitsberechnung), Validator
              (Regelprüfung), GameController (Riverpod-Notifier mit der
              gesamten Spiel-Zustandsmaschine), SettingsController.
  services/   Persistenz (SharedPreferences) für Spielstand und
              Einstellungen, PuzzleGenerationService (führt den Generator
              in einem Isolate via compute() aus, damit die Puzzle-
              Generierung die UI nicht blockiert), SoundService.
  ui/         Flutter-Widgets: Screens (Home, Game, Settings) und
              wiederverwendbare Widgets (Sudoku-Raster, Zelle, Nummernpad,
              Toolbar, Gewinn-Animation).
test/
  logic/      Unit-Tests: Solver, Validator, Generator (Eindeutigkeit der
              Lösung), HintEngine, GameController.
  models/     Unit-Test für die Schwierigkeitsberechnung (Difficulty).
  widgets/    Widget-Tests für zentrale UI-Interaktionen: Zahl eingeben,
              Notiz eintragen, Undo.
```

## Features

- 9x9-Sudoku mit Zellen-Notizen (Pencil Marks) und Status
  (vorgegeben/eingetragen).
- Puzzle-Generator mit garantiert eindeutiger Lösung, vier
  Schwierigkeitsgrade (Easy/Medium/Hard/Expert), gesteuert über Clue-Anzahl
  und benötigte Lösungstechnik.
- Solver/Hint-Engine: zeigt die nächste logisch ableitbare Zahl inkl. kurzer
  Begründung, statt einfach die Lösung zu verraten.
- Zellenauswahl per Tap/Klick, Nummernpad (1-9 + Löschen), funktioniert mit
  Touch und Maus gleichermaßen.
- Notizen-Modus inkl. Ein-Klick-"Auto-Notizen" (füllt alle legalen
  Kandidaten automatisch ein).
- Hervorhebung von Zeile/Spalte/Box und gleichen Zahlen (abschaltbar).
- Fehleranzeige (abschaltbar) und Fehlerzähler mit konfigurierbarem Limit.
- Undo/Redo, Timer (pausierbar), begrenzte Hinweise pro Spiel.
- Automatisches Speichern des laufenden Spiels (übersteht App-Kill) und
  Angebot zum Fortsetzen beim nächsten Start.
- Gewinn-Erkennung mit Konfetti-Animation (Flame).
- Dark/Light Mode (folgt optional dem System), Einstellungsseite für alle
  genannten Optionen.

## Build

Voraussetzung: [Flutter SDK](https://docs.flutter.dev/get-started/install)
(stable channel; entwickelt und getestet mit Flutter 3.47.2 / Dart 3.13.2).

```bash
flutter pub get

# Android (APK)
flutter build apk

# Web
flutter build web
```

Zum lokalen Entwickeln/Debuggen:

```bash
flutter run -d chrome   # Web
flutter run             # verbundenes Android-Gerät/Emulator
```

## Tests

```bash
flutter test
```

Deckt ab: Solver (Zufallsbefüllung, Eindeutigkeitsprüfung), Generator
(Eindeutigkeit + Reproduzierbarkeit je Schwierigkeitsgrad), Validator
(Zeilen-/Spalten-/Box-Konflikte, Lösungserkennung), HintEngine
(Naked-Single-Erkennung, Schwierigkeitsberechnung), GameController
(Eingabe, Notizen, Undo/Redo, Hinweise, Auto-Notizen) sowie Widget-Tests für
Zahleneingabe, Notizeingabe und Undo über die echte `GameScreen`-UI.

## Bekannte Einschränkungen

- **Android-SDK dieser Entwicklungsumgebung**: Diese Maschine hat Android
  SDK 34 installiert, Flutter 3.47.2 verlangt SDK 36 + Build-Tools 28.0.3.
  Ein `flutter build apk` kann deshalb hier fehlschlagen, bis das Android
  SDK aktualisiert ist (`sdkmanager` bzw. Android Studio SDK Manager) und
  die Lizenzen akzeptiert wurden (`flutter doctor --android-licenses`). Der
  Code selbst ist plattformunabhängig und wurde für Web erfolgreich
  gebaut/getestet.
- **Intel-Mac-Warnung**: Flutter kündigt an, Intel-basierte Macs künftig
  nicht mehr für Android/iOS-Builds zu unterstützen (`flutter doctor`
  zeigt eine entsprechende Warnung). Für Web-Builds ist das ohne Belang.
- **Puzzle-Generierung im Web**: `compute()` nutzt auf Flutter Web keinen
  echten OS-Thread (Web-Isolates/Worker sind eingeschränkt), sondern läuft
  asynchron im selben Thread. Die UI blockiert dadurch nicht spürbar (die
  Generierung ist ein kurzer Rechenschritt), aber es ist kein echtes
  Multithreading wie auf Android.
- **Schwierigkeitsgrad-Rating**: Die Hint-Engine implementiert eine
  Teilmenge gängiger Solving-Techniken (Naked/Hidden Single, Naked Pair,
  Pointing Pair). Für Hard/Expert-Rätsel, die eine Technik jenseits dieser
  Teilmenge erfordern, meldet `HintEngine.rateDifficulty` `backtracking`
  (= "erfordert Ausprobieren/mehr als die implementierten Techniken");
  die tatsächliche Schwierigkeit wird in diesen Fällen primär über die
  Clue-Anzahl gesteuert, nicht über eine vollständige Technik-Taxonomie.
- **Sound**: Es werden keine eigenen Audio-Assets mitgeliefert. Der
  Sound-Schalter in den Einstellungen steuert System-Klicks
  (`SystemSound.play`) und Haptic-Feedback. `lib/services/sound_service.dart`
  ist bewusst so gekapselt, dass sich später echte Soundeffekte (z. B. via
  `audioplayers`/`flame_audio`) ergänzen lassen, ohne Aufrufstellen im
  restlichen Code anzupassen.
- **Undo/Redo-Historie wird nicht persistiert**: Nur der aktuelle Spielstand
  (Board, Timer, Fehler, Hinweise) wird gespeichert; die Undo/Redo-Stacks
  werden nach einem App-Neustart zurückgesetzt, um die Speichergröße klein
  zu halten.
