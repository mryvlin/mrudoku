import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Row of secondary gameplay actions: undo/redo, notes-mode toggle,
/// auto-fill notes, and the hint button.
class GameToolbarWidget extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final bool notesMode;
  final int hintsRemaining;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onToggleNotes;
  final VoidCallback onAutoFillNotes;
  final VoidCallback onHint;

  const GameToolbarWidget({
    super.key,
    required this.canUndo,
    required this.canRedo,
    required this.notesMode,
    required this.hintsRemaining,
    required this.onUndo,
    required this.onRedo,
    required this.onToggleNotes,
    required this.onAutoFillNotes,
    required this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _ToolbarButton(
            key: const ValueKey('toolbar-undo'),
            icon: Icons.undo,
            label: l10n.undoLabel,
            onTap: canUndo ? onUndo : null,
          ),
        ),
        Expanded(
          child: _ToolbarButton(
            key: const ValueKey('toolbar-redo'),
            icon: Icons.redo,
            label: l10n.redoLabel,
            onTap: canRedo ? onRedo : null,
          ),
        ),
        Expanded(
          child: _ToolbarButton(
            key: const ValueKey('toolbar-notes'),
            icon: notesMode ? Icons.edit_note : Icons.edit_outlined,
            label: l10n.notesLabel,
            isActive: notesMode,
            onTap: onToggleNotes,
          ),
        ),
        Expanded(
          child: _ToolbarButton(
            key: const ValueKey('toolbar-autonotes'),
            icon: Icons.auto_fix_high_outlined,
            label: l10n.autoNotesLabel,
            onTap: onAutoFillNotes,
          ),
        ),
        Expanded(
          child: _ToolbarButton(
            key: const ValueKey('toolbar-hint'),
            icon: Icons.lightbulb_outline,
            label: l10n.hintLabel(hintsRemaining),
            onTap: hintsRemaining > 0 ? onHint : null,
          ),
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  const _ToolbarButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = onTap == null
        ? colors.onSurface.withValues(alpha: 0.3)
        : (isActive ? colors.primary : colors.onSurfaceVariant);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}
