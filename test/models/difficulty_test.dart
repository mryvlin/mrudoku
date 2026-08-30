import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/models/difficulty.dart';

void main() {
  test('clue counts decrease as difficulty increases', () {
    expect(Difficulty.easy.clueCount, greaterThan(Difficulty.medium.clueCount));
    expect(Difficulty.medium.clueCount, greaterThan(Difficulty.hard.clueCount));
    expect(Difficulty.hard.clueCount, greaterThan(Difficulty.expert.clueCount));
  });

  test('allowed technique rank increases as difficulty increases', () {
    expect(
      Difficulty.easy.maxAllowedTechniqueRank,
      lessThan(Difficulty.medium.maxAllowedTechniqueRank),
    );
    expect(
      Difficulty.medium.maxAllowedTechniqueRank,
      lessThan(Difficulty.hard.maxAllowedTechniqueRank),
    );
    expect(
      Difficulty.hard.maxAllowedTechniqueRank,
      lessThan(Difficulty.expert.maxAllowedTechniqueRank),
    );
  });
}
