import 'package:flutter/services.dart';

/// Lightweight feedback for game actions.
///
/// The spec calls for a sound on/off setting but ships no custom audio
/// assets, so this uses the platform's built-in system sounds and haptic
/// feedback (works offline, no extra dependency). Swap the bodies below for
/// `audioplayers`/`flame_audio` calls later if custom sound effects are
/// added; the call sites in the rest of the app would not need to change.
class SoundService {
  bool enabled;

  SoundService({this.enabled = true});

  void tap() {
    if (!enabled) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
  }

  void error() {
    if (!enabled) return;
    HapticFeedback.vibrate();
  }

  void win() {
    if (!enabled) return;
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
  }
}
