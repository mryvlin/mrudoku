import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// Shows a brief confetti burst as a full-screen overlay when the player
/// solves the puzzle. This is the one spot in the app where Flame earns its
/// keep over plain Flutter widgets - a physics-driven particle burst would
/// be awkward to hand-roll with `AnimatedContainer`/`Tween`s.
void showWinCelebration(BuildContext context) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => IgnorePointer(
      child: GameWidget(game: _ConfettiGame(onFinished: () => entry.mounted ? entry.remove() : null)),
    ),
  );
  overlay.insert(entry);
}

class _ConfettiGame extends FlameGame {
  final VoidCallback onFinished;
  final Random _random = Random();
  bool _spawned = false;

  _ConfettiGame({required this.onFinished});

  static const _colors = [
    Colors.amber,
    Colors.pinkAccent,
    Colors.lightBlueAccent,
    Colors.greenAccent,
    Colors.deepPurpleAccent,
    Colors.orangeAccent,
  ];

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (_spawned || size.x == 0) return;
    _spawned = true;
    _spawnConfetti(size);
  }

  void _spawnConfetti(Vector2 size) {
    final particle = Particle.generate(
      count: 140,
      lifespan: 2.4,
      generator: (i) {
        final color = _colors[_random.nextInt(_colors.length)];
        final startX = _random.nextDouble() * size.x;
        final angle = (_random.nextDouble() - 0.5) * (pi / 2);
        final speed = 220 + _random.nextDouble() * 260;

        return AcceleratedParticle(
          position: Vector2(startX, -20),
          speed: Vector2(sin(angle) * speed, speed * 0.6),
          acceleration: Vector2(0, 320),
          child: RotatingParticle(
            to: (_random.nextDouble() - 0.5) * 6 * pi,
            child: CircleParticle(
              radius: 3 + _random.nextDouble() * 3,
              paint: Paint()..color = color,
            ),
          ),
        );
      },
    );

    add(ParticleSystemComponent(particle: particle));
    Future<void>.delayed(const Duration(milliseconds: 2600), onFinished);
  }
}
