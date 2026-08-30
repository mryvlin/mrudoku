import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/settings.dart';

/// Loads and saves [Settings] locally via `shared_preferences`. No cloud
/// dependency - everything works fully offline.
class SettingsService {
  static const _key = 'mrsudoku.settings';

  const SettingsService();

  Future<Settings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return const Settings();
    try {
      return Settings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupted or outdated data: fall back to defaults rather than crash.
      return const Settings();
    }
  }

  Future<void> save(Settings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(settings.toJson()));
  }
}
