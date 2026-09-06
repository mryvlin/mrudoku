import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/game_state.dart';
import 'game_controller.dart';
import 'service_providers.dart';

/// Whether a game was saved from a previous session, so the Home screen can
/// offer to continue it.
///
/// While a game is active in memory (see [gameControllerProvider]),
/// including right after it's cleared by `abandonGame`, this mirrors that
/// state directly - watching it, rather than re-reading persistence on
/// every edit, is what makes this provider (and therefore Home, which
/// watches it) stay live with zero extra disk I/O. Persistence is only
/// actually read on a cold start, before any game has been restored or
/// started this session.
final savedGameProvider = FutureProvider<GameState?>((ref) async {
  final active = ref.watch(gameControllerProvider);
  if (active != null) return active;
  final persistence = ref.watch(gamePersistenceServiceProvider);
  return persistence.load();
});
