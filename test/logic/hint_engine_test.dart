import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/logic/hint_engine.dart';
import 'package:mrsudoku/models/board.dart';

void main() {
  group('HintEngine', () {
    test('finds a naked single as the last empty cell in a row', () {
      final values = [
        [5, 3, 4, 6, 7, 8, 9, 1, 0], // only '2' can go at (0, 8)
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        [1, 9, 8, 3, 4, 2, 5, 6, 7],
        [8, 5, 9, 7, 6, 1, 4, 2, 3],
        [4, 2, 6, 8, 5, 3, 7, 9, 1],
        [7, 1, 3, 9, 2, 4, 8, 5, 6],
        [9, 6, 1, 5, 3, 7, 2, 8, 4],
        [2, 8, 7, 4, 1, 9, 6, 3, 5],
        [3, 4, 5, 2, 8, 6, 1, 7, 9],
      ];
      final board = Board.fromValues(values);

      final step = HintEngine.nextLogicalStep(board);

      expect(step, isNotNull);
      expect(step!.row, 0);
      expect(step.col, 8);
      expect(step.value, 2);
      expect(step.technique, SolvingTechnique.nakedSingle);
    });

    test('returns null on a fully solved board', () {
      final values = [
        [5, 3, 4, 6, 7, 8, 9, 1, 2],
        [6, 7, 2, 1, 9, 5, 3, 4, 8],
        [1, 9, 8, 3, 4, 2, 5, 6, 7],
        [8, 5, 9, 7, 6, 1, 4, 2, 3],
        [4, 2, 6, 8, 5, 3, 7, 9, 1],
        [7, 1, 3, 9, 2, 4, 8, 5, 6],
        [9, 6, 1, 5, 3, 7, 2, 8, 4],
        [2, 8, 7, 4, 1, 9, 6, 3, 5],
        [3, 4, 5, 2, 8, 6, 1, 7, 9],
      ];
      final board = Board.fromValues(values);

      expect(HintEngine.nextLogicalStep(board), isNull);
      expect(HintEngine.rateDifficulty(board), SolvingTechnique.nakedSingle);
    });
  });
}
