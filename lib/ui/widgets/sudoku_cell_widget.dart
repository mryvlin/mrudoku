import 'package:flutter/material.dart';

import '../../models/cell.dart';

/// A single cell of the Sudoku grid: shows either the entered digit or the
/// small 3x3 pencil-mark grid of candidate notes.
class SudokuCellWidget extends StatelessWidget {
  final Cell cell;
  final bool isSelected;
  final bool isPeerHighlighted;
  final bool isSameValueHighlighted;
  final bool isError;
  final bool isThickRightBorder;
  final bool isThickBottomBorder;
  final VoidCallback onTap;

  /// The currently "active" digit (from the selected cell), or 0 if none.
  /// Used to emphasize matching pencil-mark notes even in cells that don't
  /// have that digit entered as a value yet.
  final int highlightedValue;

  /// Tint used for selection/peer/same-value/matching-note emphasis,
  /// resolved by the caller from the user's chosen [HighlightColor] (see
  /// `ui/highlight_colors.dart`) - kept separate from `colorScheme.primary`
  /// so it can be tuned independently of the app's overall theme.
  final Color highlightColor;

  const SudokuCellWidget({
    super.key,
    required this.cell,
    required this.isSelected,
    required this.isPeerHighlighted,
    required this.isSameValueHighlighted,
    required this.isError,
    required this.isThickRightBorder,
    required this.isThickBottomBorder,
    required this.onTap,
    required this.highlightColor,
    this.highlightedValue = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final highlight = highlightColor;

    final hasMatchingNote =
        highlightedValue != 0 && cell.isEmpty && cell.notes.contains(highlightedValue);

    final Color background;
    if (isSelected) {
      background = highlight.withValues(alpha: 0.35);
    } else if (isSameValueHighlighted) {
      background = highlight.withValues(alpha: 0.20);
    } else if (hasMatchingNote) {
      background = highlight.withValues(alpha: 0.12);
    } else if (isPeerHighlighted) {
      background = highlight.withValues(alpha: 0.08);
    } else {
      background = colors.surface;
    }

    final thinBorder = BorderSide(color: colors.outlineVariant, width: 0.6);
    final thickBorder = BorderSide(color: colors.outline, width: 1.6);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: background,
          border: Border(
            right: isThickRightBorder ? thickBorder : thinBorder,
            bottom: isThickBottomBorder ? thickBorder : thinBorder,
          ),
        ),
        alignment: Alignment.center,
        child: cell.isEmpty ? _buildNotes(theme) : _buildValue(theme, isSameValueHighlighted || isSelected),
      ),
    );
  }

  Widget _buildValue(ThemeData theme, bool isHighlighted) {
    final color = isError
        ? theme.colorScheme.error
        : isHighlighted
            ? highlightColor
            : cell.isGiven
                ? theme.colorScheme.onSurface
                : theme.colorScheme.primary;
    return Text(
      '${cell.value}',
      style: theme.textTheme.headlineSmall?.copyWith(
        color: color,
        fontWeight: isHighlighted ? FontWeight.w800 : (cell.isGiven ? FontWeight.w700 : FontWeight.w500),
      ),
    );
  }

  Widget _buildNotes(ThemeData theme) {
    if (cell.notes.isEmpty) return const SizedBox.expand();
    final normalStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      height: 1,
      fontSize: 12,
    );
    final matchingStyle = normalStyle?.copyWith(
      color: highlightColor,
      fontWeight: FontWeight.w800,
    );
    return Padding(
      padding: const EdgeInsets.all(1),
      child: Column(
        children: [
          for (var row = 0; row < 3; row++)
            Expanded(
              child: Row(
                children: [
                  for (var col = 0; col < 3; col++)
                    Expanded(
                      child: Center(
                        child: Builder(builder: (context) {
                          final digit = row * 3 + col + 1;
                          if (!cell.notes.contains(digit)) return const SizedBox.shrink();
                          final isMatching = digit == highlightedValue;
                          final text = Text(
                            '$digit',
                            style: isMatching ? matchingStyle : normalStyle,
                          );
                          if (!isMatching) return text;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              border: Border.all(color: highlightColor, width: 1),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: text,
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
