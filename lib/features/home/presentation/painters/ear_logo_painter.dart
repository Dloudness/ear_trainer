import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Three nested ear-contour strokes — matches reference mockup mark.
class EarLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [AppColors.cyan, AppColors.purpleLight, AppColors.blue],
    ).createShader(rect);

    Paint stroke(double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..shader = gradient;

    final pivot = Offset(size.width * 0.38, size.height * 0.52);

    // Soft halo — single pass
    for (final spec in [(r: 0.40, w: 1.8), (r: 0.30, w: 1.6), (r: 0.20, w: 1.4)]) {
      canvas.drawArc(
        Rect.fromCircle(center: pivot, radius: size.width * spec.r),
        math.pi * 0.52,
        math.pi * 0.88,
        false,
        stroke(spec.w)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5)
          ..color = AppColors.cyan.withValues(alpha: 0.08)
          ..shader = null,
      );
    }

    // Three concentric ear strokes — reference mockup
    const strokes = [
      (radius: 0.40, sweep: 0.90, width: 1.25),
      (radius: 0.30, sweep: 0.86, width: 1.10),
      (radius: 0.20, sweep: 0.80, width: 1.00),
    ];

    for (final s in strokes) {
      canvas.drawArc(
        Rect.fromCircle(center: pivot, radius: size.width * s.radius),
        math.pi * 0.54,
        math.pi * s.sweep,
        false,
        stroke(s.width),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
