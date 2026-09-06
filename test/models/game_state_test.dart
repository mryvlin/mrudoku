import 'package:flutter_test/flutter_test.dart';
import 'package:mrsudoku/models/board.dart';
import 'package:mrsudoku/models/difficulty.dart';
import 'package:mrsudoku/models/game_state.dart';

GameState _state({int hintsUsed = 0, int maxHints = 5}) => GameState(
      board: Board.empty(),
      solution: Board.empty(),
      difficulty: Difficulty.easy,
      hintsUsed: hintsUsed,
      maxHints: maxHints,
    );

void main() {
  test('defaults to 5 max hints', () {
    expect(_state().maxHints, 5);
    expect(_state().hintsRemaining, 5);
  });

  test('hintsRemaining follows the configured max hints', () {
    expect(_state(maxHints: 8).hintsRemaining, 8);
    expect(_state(hintsUsed: 2, maxHints: 8).hintsRemaining, 6);
  });

  test('hintsRemaining never goes negative even if hintsUsed exceeds maxHints', () {
    expect(_state(hintsUsed: 10, maxHints: 3).hintsRemaining, 0);
  });

  test('toJson/fromJson round-trips maxHints', () {
    final restored = GameState.fromJson(_state(maxHints: 8).toJson());
    expect(restored.maxHints, 8);
  });

  test('fromJson falls back to 5 max hints for an older save missing the field', () {
    final json = _state().toJson()..remove('maxHints');
    expect(GameState.fromJson(json).maxHints, 5);
  });

  test('toJson/fromJson round-trips isWon so a completed game resumes as won', () {
    final won = GameState(
      board: Board.empty(),
      solution: Board.empty(),
      difficulty: Difficulty.easy,
      isWon: true,
    );
    final restored = GameState.fromJson(won.toJson());
    expect(restored.isWon, isTrue);
  });

  test('fromJson falls back to isWon: false for an older save missing the field', () {
    final json = _state().toJson()..remove('isWon');
    expect(GameState.fromJson(json).isWon, isFalse);
  });
}
