import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ear Trainer mark: an ear inside the glass orb of the player, with a
/// rotating gradient ring and soft pulses. [animated] false draws it still.
class OrbLogo extends StatefulWidget {
  const OrbLogo({super.key, this.size = 260, this.animated = true});

  final double size;
  final bool animated;

  @override
  State<OrbLogo> createState() => _OrbLogoState();
}

class _OrbLogoState extends State<OrbLogo> with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    if (widget.animated) {
      _spin.repeat();
      _pulse.repeat();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final disc = size * 0.754;

    return Semantics(
      image: true,
      label: 'Ear Trainer',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.animated)
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => Stack(
                  alignment: Alignment.center,
                  children: [
                    _pulseRing(size, _pulse.value, AppColors.cyan),
                    _pulseRing(
                      size,
                      (_pulse.value + 0.5) % 1,
                      AppColors.purpleLight,
                    ),
                  ],
                ),
              ),
            AnimatedBuilder(
              animation: _spin,
              builder: (context, _) => CustomPaint(
                size: Size.square(size),
                painter: _RingPainter(turn: _spin.value),
              ),
            ),
            Container(
              width: disc,
              height: disc,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.3, -0.44),
                  radius: 0.9,
                  colors: [
                    Colors.white.withValues(alpha: 0.14),
                    Colors.white.withValues(alpha: 0.02),
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: size * 0.3,
                    offset: Offset(0, size * 0.15),
                  ),
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.25),
                    blurRadius: size * 0.23,
                  ),
                ],
              ),
            ),
            CustomPaint(
              size: Size(disc * 0.53, disc * 0.63),
              painter: _EarPainter(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pulseRing(double size, double t, Color color) {
    final base = size * 0.615;
    return Opacity(
      opacity: (0.5 * (1 - t)).clamp(0.0, 1.0),
      child: Container(
        width: base * (1 + 0.45 * t),
        height: base * (1 + 0.45 * t),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.turn});

  final double turn;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = math.max(2.0, size.width * 0.019);
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - stroke;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.07),
    );

    final start = -math.pi / 2 + 2 * math.pi * turn;
    const sweep = 2 * math.pi * 0.68;
    canvas.drawArc(
      rect,
      start,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          colors: const [
            Color(0xFF67E8F9),
            AppColors.blue,
            AppColors.purpleLight,
          ],
          endAngle: sweep,
          transform: GradientRotation(start),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.turn != turn;
  }
}

/// The ear glyph, drawn in a 76 × 108 design box.
class _EarPainter extends CustomPainter {
  static const _box = Size(76, 108);
  static const _origin = Offset(22, 4);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / _box.width, size.height / _box.height);
    canvas
      ..save()
      ..translate(
        (size.width - _box.width * scale) / 2,
        (size.height - _box.height * scale) / 2,
      )
      ..scale(scale)
      ..translate(-_origin.dx, -_origin.dy);

    final shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white, Color(0xFFA5F3FC)],
    ).createShader(Rect.fromLTWH(_origin.dx, _origin.dy, _box.width, _box.height));

    Paint stroke(double width) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = shader;

    final outer = Path()
      ..moveTo(30, 44)
      ..cubicTo(30, 22, 46, 10, 62, 10)
      ..cubicTo(80, 10, 92, 24, 92, 44)
      ..cubicTo(92, 60, 80, 66, 76, 78)
      ..cubicTo(72, 92, 66, 106, 50, 106)
      ..cubicTo(40, 106, 34, 98, 34, 90);
    final inner = Path()
      ..moveTo(46, 46)
      ..cubicTo(46, 34, 54, 26, 64, 26)
      ..cubicTo(74, 26, 78, 36, 76, 44)
      ..cubicTo(74, 52, 64, 54, 62, 62)
      ..cubicTo(60, 70, 66, 74, 60, 80);

    canvas
      ..drawPath(outer, stroke(6))
      ..drawPath(inner, stroke(5))
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _EarPainter oldDelegate) => false;
}
