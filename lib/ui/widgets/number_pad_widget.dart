import 'package:flutter/material.dart';

/// Number input pad (1-9 + delete), usable via touch or mouse click alike.
class NumberPadWidget extends StatelessWidget {
  final void Function(int value) onNumberTap;
  final VoidCallback onEraseTap;

  /// How many times each digit (1-9) can still be legally placed
  /// (9 minus how often it already appears on the board). A fully placed
  /// digit's button is greyed out and disabled as a small solving aid.
  final Map<int, int> remainingCounts;

  const NumberPadWidget({
    super.key,
    required this.onNumberTap,
    required this.onEraseTap,
    this.remainingCounts = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var value = 1; value <= 9; value++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _NumberButton(
                key: ValueKey('numpad-$value'),
                value: value,
                remaining: remainingCounts[value],
                onTap: () => onNumberTap(value),
              ),
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _EraseButton(key: const ValueKey('numpad-erase'), onTap: onEraseTap),
          ),
        ),
      ],
    );
  }
}

class _NumberButton extends StatelessWidget {
  final int value;
  final int? remaining;
  final VoidCallback onTap;

  const _NumberButton({super.key, required this.value, required this.remaining, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final disabled = remaining != null && remaining! <= 0;

    return Material(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 0.75,
          child: Center(
            child: Text(
              '$value',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: disabled ? colors.onSurface.withValues(alpha: 0.3) : colors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EraseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _EraseButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AspectRatio(
          aspectRatio: 0.75,
          child: Center(
            child: Icon(Icons.backspace_outlined, color: colors.onSurface),
          ),
        ),
      ),
    );
  }
}
