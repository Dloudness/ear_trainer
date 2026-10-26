import 'package:flutter/material.dart';

class HomeAnimations {
  HomeAnimations({required TickerProvider vsync}) {
    ambient = AnimationController(
      vsync: vsync,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);

    wave = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 4800),
    )..repeat();

    pulse = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
  }

  late final AnimationController ambient;
  late final AnimationController wave;
  late final AnimationController pulse;

  void dispose() {
    ambient.dispose();
    wave.dispose();
    pulse.dispose();
  }
}
