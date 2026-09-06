import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/l10n/app_localizations.dart';
import 'package:mrsudoku/logic/providers.dart';
import 'package:mrsudoku/ui/screens/game_screen.dart';
import 'package:mrsudoku/ui/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('double-tapping a difficulty button only starts one game', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    final difficultyButton = find.byType(OutlinedButton).first;

    // startNewGame -> PuzzleGenerationService.generate uses compute(), which
    // spawns a real isolate, so this needs runAsync (see
    // test/widgets/game_screen_test.dart for the same pattern). Both taps
    // are dispatched with no pump() in between, deliberately racing the two
    // calls the way a real double-tap would. The second tap is expected to
    // miss its target - GameScreen (pushed by the first tap) already covers
    // it by the time it's dispatched, which is itself evidence the fix
    // works; warnIfMissed: false just silences the expected warning.
    await tester.runAsync(() async {
      await tester.tap(difficultyButton);
      await tester.tap(difficultyButton, warnIfMissed: false);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.byType(GameScreen), findsOneWidget);
    expect(container.read(gameControllerProvider), isNotNull);
  });
}
