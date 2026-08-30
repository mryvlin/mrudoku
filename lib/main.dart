import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logic/providers.dart';
import 'models/settings.dart';
import 'ui/screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: MrSudokuApp()));
}

/// App root: wires up Material 3 theming (light/dark, following the user's
/// [AppThemeMode] setting) around the [HomeScreen].
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
      home: const HomeScreen(),
    );
  }
}
