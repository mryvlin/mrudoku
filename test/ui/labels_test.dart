import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/l10n/app_localizations.dart';
import 'package:mrsudoku/models/difficulty.dart';
import 'package:mrsudoku/models/settings.dart';
import 'package:mrsudoku/ui/difficulty_labels.dart';
import 'package:mrsudoku/ui/highlight_colors.dart';

void main() {
  final de = lookupAppLocalizations(const Locale('de'));
  final en = lookupAppLocalizations(const Locale('en'));

  test('Difficulty.label is localized', () {
    expect(Difficulty.easy.label(de), 'Einfach');
    expect(Difficulty.easy.label(en), 'Easy');
    expect(Difficulty.expert.label(de), 'Experte');
    expect(Difficulty.expert.label(en), 'Expert');
  });

  test('HighlightColor.label is localized', () {
    expect(HighlightColor.blue.label(de), 'Blau');
    expect(HighlightColor.blue.label(en), 'Blue');
  });
}
