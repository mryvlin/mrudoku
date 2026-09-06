import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/models/settings.dart';

void main() {
  test('defaults to the red highlight color', () {
    expect(const Settings().highlightColor, HighlightColor.red);
  });

  test('toJson/fromJson round-trips the chosen highlight color', () {
    const settings = Settings(highlightColor: HighlightColor.blue);
    final restored = Settings.fromJson(settings.toJson());
    expect(restored.highlightColor, HighlightColor.blue);
  });

  test('fromJson falls back to red for a missing or unknown highlight color', () {
    expect(Settings.fromJson(const {}).highlightColor, HighlightColor.red);
    expect(
      Settings.fromJson(const {'highlightColor': 'not-a-real-color'}).highlightColor,
      HighlightColor.red,
    );
  });

  test('copyWith updates only the highlight color', () {
    const settings = Settings(highlightColor: HighlightColor.green);
    final updated = settings.copyWith(highlightColor: HighlightColor.purple);
    expect(updated.highlightColor, HighlightColor.purple);
    expect(updated.highlightEnabled, settings.highlightEnabled);
  });
}
