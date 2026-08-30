import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/logic/validator.dart';
import 'package:mrsudoku/models/board.dart';

const _validSolution = [
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

void main() {
  group('Validator', () {
    test('detects a row conflict', () {
      final values = List.generate(9, (_) => List.filled(9, 0));
      values[0][0] = 5;
      values[0][1] = 5;
      final board = Board.fromValues(values);

      expect(Validator.isValidPlacement(board, 0, 1, 5), isFalse);
      expect(Validator.conflictsFor(board, 0, 1, 5), contains((0, 0)));
    });

    test('detects a column conflict', () {
      final values = List.generate(9, (_) => List.filled(9, 0));
      values[0][3] = 7;
      values[5][3] = 7;
      final board = Board.fromValues(values);

      expect(Validator.isValidPlacement(board, 5, 3, 7), isFalse);
    });

    test('detects a box conflict', () {
      final values = List.generate(9, (_) => List.filled(9, 0));
      values[0][0] = 9;
      values[1][1] = 9;
      final board = Board.fromValues(values);

      expect(Validator.isValidPlacement(board, 1, 1, 9), isFalse);
    });

    test('a valid, complete grid has no conflicts and is solved', () {
      final board = Board.fromValues(_validSolution);
      expect(Validator.allConflicts(board), isEmpty);
      expect(Validator.isSolved(board), isTrue);
    });

    test('an incomplete grid is never reported as solved', () {
      final values = [for (final row in _validSolution) [...row]];
      values[0][0] = 0;
      final board = Board.fromValues(values);
      expect(Validator.isSolved(board), isFalse);
    });
  });
}
