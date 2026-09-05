import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import 'service_providers.dart';

export 'game_controller.dart';
export 'leaderboard_controller.dart';
export 'service_providers.dart';
export 'settings_controller.dart';

/// Whether a game was saved from a previous session, checked once at
/// startup so the Home screen can offer to continue it.
final savedGameProvider = FutureProvider<GameState?>((ref) async {
  final persistence = ref.watch(gamePersistenceServiceProvider);
  return persistence.load();
});
