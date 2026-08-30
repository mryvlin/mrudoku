/// Represents a single cell of the 9x9 Sudoku grid.
///
/// A cell is immutable; every change (value, notes, ...) creates a new
/// [Cell] instance via [copyWith]. This makes the model easy to reason
/// about and plays well with the undo/redo history in the game controller.
class Cell {
  /// The current digit in the cell, 1-9. `0` means the cell is empty.
  final int value;

  /// Pencil-mark candidates (1-9) the player noted for this cell.
  final Set<int> notes;

  /// `true` if this cell was part of the original puzzle (a "given") and
  /// therefore cannot be edited by the player.
  final bool isGiven;

  const Cell({
    this.value = 0,
    this.notes = const <int>{},
    this.isGiven = false,
  });

  bool get isEmpty => value == 0;

  Cell copyWith({
    int? value,
    Set<int>? notes,
    bool? isGiven,
    bool clearNotes = false,
  }) {
    return Cell(
      value: value ?? this.value,
      notes: clearNotes ? const <int>{} : (notes ?? this.notes),
      isGiven: isGiven ?? this.isGiven,
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'notes': notes.toList(),
        'isGiven': isGiven,
      };

  factory Cell.fromJson(Map<String, dynamic> json) => Cell(
        value: json['value'] as int,
        notes: (json['notes'] as List<dynamic>).map((e) => e as int).toSet(),
        isGiven: json['isGiven'] as bool,
      );

  @override
  bool operator ==(Object other) =>
      other is Cell &&
      other.value == value &&
      other.isGiven == isGiven &&
      other.notes.length == notes.length &&
      other.notes.containsAll(notes);

  @override
  int get hashCode => Object.hash(value, isGiven, Object.hashAllUnordered(notes));
}
