import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'logic/providers.dart';
import 'models/settings.dart';
import 'ui/screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: MrSudokuApp()));
}

/// App root: wires up Material 3 theming (light/dark, following the user's
/// [AppThemeMode] setting) and localization (following [AppLocale]) around
/// the [HomeScreen].
class MrSudokuApp extends ConsumerWidget {
  const MrSudokuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);

    final themeMode = switch (settings.themeMode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    };

    final locale = switch (settings.locale) {
      AppLocale.system => null, // let Flutter resolve it from the OS locale
      AppLocale.de => const Locale('de'),
      AppLocale.en => const Locale('en'),
    };

    return MaterialApp(
      title: 'mrsudoku',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
      ),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );
  }
}
