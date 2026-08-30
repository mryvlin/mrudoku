import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/game_persistence_service.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';

final gamePersistenceServiceProvider = Provider((ref) => const GamePersistenceService());
final settingsServiceProvider = Provider((ref) => const SettingsService());
final soundServiceProvider = Provider((ref) => SoundService());
