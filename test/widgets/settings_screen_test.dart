import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/logic/providers.dart';
import 'package:mrsudoku/models/settings.dart';
import 'package:mrsudoku/ui/screens/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('tapping a highlight color swatch updates the setting', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pump();

    expect(container.read(settingsControllerProvider).highlightColor, HighlightColor.red);

    await tester.tap(find.byTooltip(HighlightColor.blue.label));
    await tester.pump();

    expect(container.read(settingsControllerProvider).highlightColor, HighlightColor.blue);
  });
}
