import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/settings.dart';
import '../services/settings_service.dart';
import 'service_providers.dart';

/// Loads [Settings] on startup and persists every change.
class SettingsController extends Notifier<Settings> {
  SettingsService get _service => ref.read(settingsServiceProvider);

  @override
  Settings build() {
    _load();
    return const Settings();
  }

  Future<void> _load() async => state = await _service.load();

  Future<void> _update(Settings Function(Settings current) updater) async {
    state = updater(state);
    await _service.save(state);
  }

  Future<void> setErrorLimitEnabled(bool value) => _update((s) => s.copyWith(errorLimitEnabled: value));
  Future<void> setMaxMistakes(int value) => _update((s) => s.copyWith(maxMistakes: value));
  Future<void> setHighlightEnabled(bool value) => _update((s) => s.copyWith(highlightEnabled: value));
  Future<void> setHighlightColor(HighlightColor value) =>
      _update((s) => s.copyWith(highlightColor: value));
  Future<void> setShowErrors(bool value) => _update((s) => s.copyWith(showErrors: value));
  Future<void> setThemeMode(AppThemeMode value) => _update((s) => s.copyWith(themeMode: value));
  Future<void> setSoundEnabled(bool value) => _update((s) => s.copyWith(soundEnabled: value));
}

final settingsControllerProvider = NotifierProvider<SettingsController, Settings>(SettingsController.new);
