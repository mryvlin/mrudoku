import 'package:flutter/material.dart';

import '../models/board_layout.dart';
import '../models/difficulty.dart';

/// Fixed dark color palette for the Home screen's redesign - deliberately
/// independent of `Theme.of(context)`/[AppThemeMode], since this look is
/// meant to always show regardless of the user's light/dark/system theme
/// setting (a distinct visual identity for the landing screen, not a theme
/// variant). Shared between `home_screen.dart` and `leaderboard_widget.dart`
/// so the leaderboard card's colors and the screen around it stay in sync.
class HomePalette {
  const HomePalette._();

  static const background = Color(0xFF0A0A12);
  static const card = Color(0xFF15151F);
  static const border = Color(0xFF2A2A3D);
  static const primaryText = Colors.white;
  static const mutedText = Color(0xFF8A8AA3);
  static const gold = Color(0xFFFFC940);

  static const gradientStart = Color(0xFF5B6EF5);
  static const gradientEnd = Color(0xFF9B5CF6);
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );

  /// Tag color for a leaderboard difficulty group. A non-classic layout
  /// gets one shared accent (teal) regardless of difficulty, so a Samurai
  /// time reads as visually distinct from a classic one at the same
  /// difficulty rather than reusing that difficulty's own color.
  static Color tagColor(Difficulty difficulty, BoardLayout layout) {
    if (layout != BoardLayout.classic) return const Color(0xFF2DD4C8);
    switch (difficulty) {
      case Difficulty.easy:
        return const Color(0xFF3DD68C);
      case Difficulty.medium:
        return const Color(0xFF4E9EF5);
      case Difficulty.hard:
        return const Color(0xFF9B6BF2);
      case Difficulty.expert:
        return const Color(0xFFE85D9E);
    }
  }
}
