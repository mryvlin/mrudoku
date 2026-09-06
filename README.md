# mrsudoku

A complete, production-ready Sudoku game as a Flutter app - runnable as an
Android app and as a web app (Flutter Web). Fully offline, no cloud
dependency, localized in German and English.

## Architecture

The core UI (grid, number entry, number pad) is built with plain Flutter
widgets instead of a pure Flame-canvas solution - for a grid-based puzzle
this is more robust, more accessible (screen reader, touch targets, layout),
and easier to maintain. Flame is used specifically where it adds real value:
the confetti particle effect when the puzzle is solved
(`lib/ui/widgets/win_celebration.dart`).

**Riverpod** (`flutter_riverpod`, the modern `Notifier`/`NotifierProvider`
API) is used for state management: it lets game logic be tested
independently of Flutter widgets (see `test/logic/game_controller_test.dart`,
which drives the controller through a `ProviderContainer` with no widget
tree at all), dependencies (persistence, sound, leaderboard) are cleanly
injected rather than referenced globally, and reactive updates to the board,
timer, and settings work without manual `setState` juggling.

**Localization** uses Flutter's standard ARB/`gen-l10n` toolchain
(`flutter_localizations`, `intl`, `lib/l10n/*.arb`), defaulting to the OS
locale (German otherwise) with an in-app override in Settings. The solving
logic stays presentation-agnostic: `HintEngine` returns structured data
(technique, position, which unit forced it) with no text at all, and
`ui/hint_text.dart` composes the localized explanation from it - keeping
`lib/logic/` free of Flutter/localization imports, consistent with the rest
of that layer.

### Project structure

```
lib/
  models/     Pure Dart, no Flutter imports: Cell, Board, Difficulty,
              Settings, GameState, LeaderboardEntry. Immutable,
              JSON-serializable for persistence.
  logic/      Pure Dart: Solver (backtracking + uniqueness check),
              Generator (produces puzzles with a unique solution), HintEngine
              (Naked/Hidden Single, Naked/Pointing Pair, Box-Line Reduction,
              Hidden Pair, Naked Triple, X-Wing - basis for hints and
              difficulty rating), Validator (rule checking), GameController
              (Riverpod Notifier with the entire game state machine),
              SettingsController, LeaderboardController, and the
              saved-game provider that backs Home's resume offer.
  services/   Persistence (SharedPreferences) for game state, settings and
              the leaderboard, PuzzleGenerationService (runs the generator
              in an isolate via compute() so puzzle generation doesn't
              block the UI), SoundService.
  l10n/       ARB source strings (`app_de.arb`, `app_en.arb`) and the
              generated `AppLocalizations` (see l10n.yaml).
  ui/         Flutter widgets: screens (Home, Game, Settings) and
              reusable widgets (Sudoku grid, cell, number pad, toolbar,
              leaderboard card, win animation), plus small UI-layer helpers
              that localize model enums (difficulty names, highlight color
              names, hint explanations) without pulling Flutter into
              models/ or logic/.
test/
  logic/      Unit tests: Solver, Validator, Generator (uniqueness of
              the solution), HintEngine, GameController.
  models/     Unit tests: Difficulty, Settings, GameState.
  services/   Unit tests: LeaderboardService (ranking, per-difficulty cap).
  ui/         Unit tests for the localized hint-explanation composer and
              the difficulty/highlight-color label helpers.
  widgets/    Widget tests for core UI interactions: entering a number,
              entering a note, undo, the settings screen, and the board's
              hint-focused peer highlighting.
```

## Features

- 9x9 Sudoku with cell notes (pencil marks) and status
  (given/entered). A note can only be added if it's still a legal
  candidate for the cell; a wrong number entry never erases existing
  notes (its own or a peer's) - only a confirmed-correct entry does.
- Puzzle generator with a guaranteed unique solution, four
  difficulty levels (Easy/Medium/Hard/Expert), controlled via clue count
  and required solving technique.
- Solver/hint engine covering Naked/Hidden Single, Naked Pair, Pointing
  Pair, Box-Line Reduction, Hidden Pair, Naked Triple and X-Wing. A hint
  shows the next logically derivable number with a short explanation in a
  persistent banner (not a timed snackbar), and - for a hidden single -
  narrows the board's highlight down to the exact row/column/box that
  forced it, instead of just revealing the answer. Number of hints per
  game is configurable (default 5).
- Cell selection via tap/click, number pad (1-9 + erase), works with
  touch and mouse alike.
- Notes mode including one-click "auto-notes" (fills in all legal
  candidates automatically).
- Highlighting of row/column/box and matching numbers (can be turned off),
  with a selectable accent color (red/orange/green/blue/purple/teal).
- Error display (can be turned off) and mistake counter with a configurable
  limit.
- Undo/redo, timer (pausable).
- Robust autosave: the game in progress is saved after nearly every move,
  flushed immediately when leaving the game screen (back button/gesture) or
  when the app is backgrounded/closed, and offered for resume on the next
  launch - or the player can start a new game instead, replacing the save.
- Local leaderboard: the fastest completion times per difficulty are
  tracked and shown on the Home screen.
- Win detection with confetti animation (Flame).
- Dark/light mode and language (German/English) each optionally follow the
  system; a settings screen covers all of the above.

## Build

Prerequisite: [Flutter SDK](https://docs.flutter.dev/get-started/install)
(stable channel; developed and tested with Flutter 3.47.2 / Dart 3.13.2).

```bash
flutter pub get

# Android (APK)
flutter build apk

# Web
flutter build web
```

`flutter pub get` also regenerates `lib/l10n/app_localizations*.dart` from
the ARB files (`generate: true` in `pubspec.yaml`); run `flutter gen-l10n`
directly after editing an ARB file if you want the generated code refreshed
without a full `pub get`.

For local development/debugging:

```bash
flutter run -d chrome   # Web
flutter run             # connected Android device/emulator
```

## Tests

```bash
flutter test
```

Covers: Solver (randomized fill, uniqueness check), Generator (uniqueness +
reproducibility per difficulty level), Validator (row/column/box conflicts,
solved-state detection), HintEngine (every implemented technique down to
X-Wing, difficulty rating), GameController (input, notes and their
legality/preservation rules, undo/redo, hints, auto-notes, autosave/resume,
leaderboard recording), LeaderboardService (ranking and per-difficulty cap),
Settings/GameState (defaults, JSON round-trips), the localized hint-text and
label helpers, and widget tests for number entry, note entry, undo, the
settings screen, and the board's hint-focused highlighting - through the
real `GameScreen`/`SettingsScreen`/`SudokuBoardWidget` UI.

## Known limitations

- **Android SDK licenses in this development environment**: The Android SDK
  itself is at the version Flutter 3.47.2 expects, but `flutter doctor`
  reports outstanding license agreements; `flutter build apk` may fail here
  until they're accepted (`flutter doctor --android-licenses`). The code
  itself is platform-independent and has been successfully built/tested for
  web.
- **Intel Mac warning**: Flutter has announced it will stop supporting
  Intel-based Macs for Android/iOS builds in the future (`flutter doctor`
  shows a corresponding warning). This is irrelevant for web builds.
- **Puzzle generation on web**: `compute()` doesn't use a real OS thread on
  Flutter Web (web isolates/workers are limited), but instead runs
  asynchronously on the same thread. This doesn't noticeably block the UI
  (generation is a short computation), but it isn't real multithreading
  like on Android.
- **Difficulty rating**: The hint engine implements a substantial but still
  partial set of solving techniques (see Features above). For Hard/Expert
  puzzles that require a technique beyond that set,
  `HintEngine.rateDifficulty` reports `backtracking` (= "requires trial and
  error/more than the implemented techniques"); in these cases the actual
  difficulty is controlled primarily via the clue count, not via a complete
  technique taxonomy.
- **Sound**: No custom audio assets are shipped. The sound toggle in
  settings controls system clicks (`SystemSound.play`) and haptic feedback.
  `lib/services/sound_service.dart` is deliberately encapsulated so that
  real sound effects (e.g. via `audioplayers`/`flame_audio`) can be added
  later without touching call sites elsewhere in the code.
- **Undo/redo history is not persisted**: Only the current game state
  (board, timer, mistakes, hints) is saved; the undo/redo stacks are reset
  after an app restart to keep the save size small.
- **Leaderboard is local-only**: Times are stored on-device
  (`shared_preferences`), per difficulty, capped at the 10 fastest; there's
  no cross-device sync or global ranking.
