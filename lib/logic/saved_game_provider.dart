import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import 'service_providers.dart';

/// Whether a game was saved from a previous session, so the Home screen can
/// offer to continue it. [GameController] invalidates this every time it
/// writes or clears the save, so Home always reflects the latest state when
/// the player navigates back to it (e.g. after backing out of a game).
final savedGameProvider = FutureProvider<GameState?>((ref) async {
  final persistence = ref.watch(gamePersistenceServiceProvider);
  return persistence.load();
});
