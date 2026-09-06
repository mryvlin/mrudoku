import '../l10n/app_localizations.dart';
import '../logic/hint_engine.dart';
import '../models/board.dart';

/// Composes the localized hint message shown in the Game screen's snackbar
/// from a structured [HintStep]. Kept in the UI layer since `hint_engine.dart`
/// is pure solving logic with no text/localization concerns of its own.
String describeHint(HintStep step, AppLocalizations l10n) {
  if (step.technique == SolvingTechnique.backtracking) {
    return l10n.hintDirectReveal;
  }

  final base = step.singleKind == SingleKind.hidden
      ? l10n.hintHiddenSingle(_unitLabel(step, l10n), step.value, step.row + 1, step.col + 1)
      : l10n.hintNakedSingle(step.row + 1, step.col + 1, step.value);
  final leadIn = _leadIn(step.technique, l10n);
  final body = leadIn == null ? base : '$leadIn $base';
  return '${_techniqueLabel(step.technique, l10n)}: $body';
}

String _unitLabel(HintStep step, AppLocalizations l10n) {
  switch (step.hiddenUnit!) {
    case HintUnitType.row:
      return l10n.unitRow(step.row + 1);
    case HintUnitType.column:
      return l10n.unitColumn(step.col + 1);
    case HintUnitType.box:
      return l10n.unitBox(boxIndexOf(step.row, step.col) + 1);
  }
}

/// Short lead-in noting that a technique first had to narrow the candidates
/// down before the placed value became forced. Only meaningful for the
/// elimination-only tiers between naked/hidden single and backtracking.
String? _leadIn(SolvingTechnique technique, AppLocalizations l10n) {
  switch (technique) {
    case SolvingTechnique.pairElimination:
      return l10n.leadInPairElimination;
    case SolvingTechnique.hiddenPair:
      return l10n.leadInHiddenPair;
    case SolvingTechnique.nakedTriple:
      return l10n.leadInNakedTriple;
    case SolvingTechnique.xWing:
      return l10n.leadInXWing;
    case SolvingTechnique.nakedSingle:
    case SolvingTechnique.hiddenSingle:
    case SolvingTechnique.backtracking:
      return null;
  }
}

String _techniqueLabel(SolvingTechnique technique, AppLocalizations l10n) {
  switch (technique) {
    case SolvingTechnique.nakedSingle:
      return l10n.techniqueNakedSingle;
    case SolvingTechnique.hiddenSingle:
      return l10n.techniqueHiddenSingle;
    case SolvingTechnique.pairElimination:
      return l10n.techniquePairElimination;
    case SolvingTechnique.hiddenPair:
      return l10n.techniqueHiddenPair;
    case SolvingTechnique.nakedTriple:
      return l10n.techniqueNakedTriple;
    case SolvingTechnique.xWing:
      return l10n.techniqueXWing;
    case SolvingTechnique.backtracking:
      return l10n.techniqueBacktracking;
  }
}
