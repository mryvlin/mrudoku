import 'package:flutter/material.dart';

import '../models/settings.dart';

/// Maps a [HighlightColor] choice to actual paint colors. Kept in the UI
/// layer so `models/settings.dart` stays free of Flutter imports.
extension HighlightColorX on HighlightColor {
  /// The color used to paint selection/peer/same-value highlighting on the
  /// board, shifted to a lighter shade in dark mode for contrast against a
  /// dark surface.
  Color resolve(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (this) {
      case HighlightColor.red:
        return isDark ? Colors.red.shade300 : Colors.red.shade700;
      case HighlightColor.orange:
        return isDark ? Colors.orange.shade300 : Colors.orange.shade800;
      case HighlightColor.green:
        return isDark ? Colors.green.shade300 : Colors.green.shade700;
      case HighlightColor.blue:
        return isDark ? Colors.lightBlue.shade300 : Colors.blue.shade700;
      case HighlightColor.purple:
        return isDark ? Colors.purple.shade200 : Colors.purple.shade700;
      case HighlightColor.teal:
        return isDark ? Colors.teal.shade300 : Colors.teal.shade700;
    }
  }

  /// Fixed, theme-independent swatch color used for the settings picker.
  Color get swatch {
    switch (this) {
      case HighlightColor.red:
        return Colors.red;
      case HighlightColor.orange:
        return Colors.orange;
      case HighlightColor.green:
        return Colors.green;
      case HighlightColor.blue:
        return Colors.blue;
      case HighlightColor.purple:
        return Colors.purple;
      case HighlightColor.teal:
        return Colors.teal;
    }
  }
}
