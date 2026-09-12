import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/l10n/app_localizations.dart';
import 'package:mrsudoku/logic/hint_engine.dart';
import 'package:mrsudoku/ui/hint_text.dart';

void main() {
  final de = lookupAppLocalizations(const Locale('de'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('a naked single is described with its row/column/value, in each locale', () {
    const step = HintStep(row: 2, col: 4, value: 7, technique: SolvingTechnique.nakedSingle);

    expect(describeHint(step, de), 'Naked Single: Zeile 3, Spalte 5 hat nur einen möglichen Kandidaten: 7.');
    expect(describeHint(step, en), 'Naked Single: Row 3, column 5 has only one possible candidate: 7.');
  });

  test('a hidden single names the unit that forced it: row', () {
    const step = HintStep(
      row: 0,
      col: 8,
      value: 2,
      technique: SolvingTechnique.hiddenSingle,
      singleKind: SingleKind.hidden,
      hiddenUnit: HintUnitType.row,
    );

    expect(describeHint(step, de), contains('In Zeile 1 kann die 2 nur noch in Zeile 1, Spalte 9 stehen.'));
  });

  test('a hidden single names the unit that forced it: column', () {
    const step = HintStep(
      row: 3,
      col: 1,
      value: 9,
      technique: SolvingTechnique.hiddenSingle,
      singleKind: SingleKind.hidden,
      hiddenUnit: HintUnitType.column,
    );

    expect(describeHint(step, de), contains('In Spalte 2 kann die 9 nur noch in Zeile 4, Spalte 2 stehen.'));
  });

  test('a hidden single names the unit that forced it: box', () {
    const step = HintStep(
      row: 4,
      col: 4,
      value: 5,
      technique: SolvingTechnique.hiddenSingle,
      singleKind: SingleKind.hidden,
      hiddenUnit: HintUnitType.box,
    );

    // Box index is derived from (row, col): (4~/3)*3 + (4~/3) + 1 = 5.
    expect(describeHint(step, de), contains('In Box 5 kann die 5 nur noch in Zeile 5, Spalte 5 stehen.'));
  });

  test('an elimination tier prepends its lead-in before the base explanation', () {
    const step = HintStep(row: 0, col: 0, value: 1, technique: SolvingTechnique.pairElimination);

    final message = describeHint(step, de);
    expect(message, startsWith('Kandidaten-Ausschluss'));
    expect(message, contains('Nach Ausschluss durch ein Paar-Muster'));
    expect(message, contains('Zeile 1, Spalte 1 hat nur einen möglichen Kandidaten: 1.'));
  });

  test('an XY-Wing step prepends its lead-in before the base explanation', () {
    const step = HintStep(row: 0, col: 0, value: 1, technique: SolvingTechnique.xyWing);

    final message = describeHint(step, de);
    expect(message, startsWith('XY-Wing'));
    expect(message, contains('Nach Ausschluss durch ein XY-Wing-Muster'));
    expect(message, contains('Zeile 1, Spalte 1 hat nur einen möglichen Kandidaten: 1.'));
  });

  test('a Swordfish step prepends its lead-in before the base explanation', () {
    const step = HintStep(row: 0, col: 0, value: 1, technique: SolvingTechnique.swordfish);

    final message = describeHint(step, de);
    expect(message, startsWith('Swordfish'));
    expect(message, contains('Nach Ausschluss durch ein Swordfish-Muster'));
    expect(message, contains('Zeile 1, Spalte 1 hat nur einen möglichen Kandidaten: 1.'));
  });

  test('the backtracking fallback ignores row/col/value and just reveals directly', () {
    const step = HintStep(row: 0, col: 0, value: 9, technique: SolvingTechnique.backtracking);

    expect(describeHint(step, de), de.hintDirectReveal);
    expect(describeHint(step, en), en.hintDirectReveal);
  });
}
