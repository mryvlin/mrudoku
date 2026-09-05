import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/logic/hint_engine.dart';
import 'package:mrsudoku/models/difficulty.dart';

void main() {
  test('expert rank tracks the hardest SolvingTechnique', () {
    // maxAllowedTechniqueRank duplicates SolvingTechnique's enum indices as
    // plain ints so models/ doesn't depend on logic/; this keeps them honest
    // whenever a new technique is added.
    expect(Difficulty.expert.maxAllowedTechniqueRank, SolvingTechnique.backtracking.rank);
  });

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
