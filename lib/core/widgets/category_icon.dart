import 'dart:math' as math;

import 'package:flutter/material.dart';

enum CategoryGlyph { frequency, dynamics, musical, video, listening }

/// Gradient-stroke glyph for a training area, inside a glass tile tinted
/// with the area's color.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.glyph,
    required this.colors,
    this.size = 48,
    this.lit = false,
  });

  final CategoryGlyph glyph;

  /// Light and deep tone of the area (top-left to bottom-right).
  final List<Color> colors;
  final double size;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    final glow = colors.last;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.31),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            glow.withValues(alpha: lit ? 0.38 : 0.28),
            glow.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: colors.first.withValues(alpha: 0.42)),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: lit ? 0.38 : 0.14),
            blurRadius: lit ? 24 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size.square(size * 0.58),
        painter: _GlyphPainter(glyph: glyph, colors: colors),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({required this.glyph, required this.colors});

  final CategoryGlyph glyph;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas
      ..save()
      ..scale(scale);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ).createShader(const Rect.fromLTWH(0, 0, 24, 24));

    switch (glyph) {
      case CategoryGlyph.frequency:
        canvas
          ..drawPath(
            Path()
              ..moveTo(2, 17)
              ..cubicTo(5.5, 17, 6.5, 7, 12, 7)
              ..cubicTo(17.5, 7, 18.5, 17, 22, 17),
            paint,
          )
          ..drawLine(const Offset(2, 20.5), const Offset(22, 20.5), paint);
      case CategoryGlyph.dynamics:
        canvas
          ..drawPath(
            _polyline(const [
              Offset(3, 12),
              Offset(5.5, 12),
              Offset(7, 7),
              Offset(9.5, 17),
              Offset(11.5, 9),
              Offset(13.5, 15),
              Offset(15, 11),
              Offset(16.5, 13.5),
              Offset(21.5, 13.5),
            ]),
            paint,
          )
          ..drawLine(const Offset(3, 4.5), const Offset(21, 4.5), paint)
          ..drawLine(const Offset(3, 19.5), const Offset(21, 19.5), paint);
      case CategoryGlyph.musical:
        canvas
          ..drawPath(
            Path()
              ..moveTo(8, 3)
              ..lineTo(8, 10)
              ..arcToPoint(
                const Offset(16, 10),
                radius: const Radius.circular(4),
                clockwise: false,
              )
              ..lineTo(16, 3),
            paint,
          )
          ..drawLine(const Offset(12, 14), const Offset(12, 21), paint)
          ..drawPath(
            Path()
              ..moveTo(19, 6.5)
              ..cubicTo(20, 7.6, 20.5, 8.8, 20.5, 10)
              ..moveTo(5, 6.5)
              ..cubicTo(4, 7.6, 3.5, 8.8, 3.5, 10),
            paint,
          );
      case CategoryGlyph.video:
        canvas
          ..drawRRect(
            RRect.fromLTRBAndCorners(
              4,
              9.5,
              20,
              20.5,
              bottomLeft: const Radius.circular(1.5),
              bottomRight: const Radius.circular(1.5),
            ),
            paint,
          )
          ..drawPath(
            _polyline(const [Offset(4, 9.5), Offset(18.6, 5.6), Offset(19.5, 9)]),
            paint,
          )
          ..drawLine(const Offset(9, 8.2), const Offset(7.4, 6.1), paint)
          ..drawLine(const Offset(14, 6.9), const Offset(12.4, 4.8), paint)
          ..drawPath(
            _polyline(const [
              Offset(7.5, 15.5),
              Offset(9, 15.5),
              Offset(10, 13.5),
              Offset(11.5, 17.5),
              Offset(13, 14.5),
              Offset(14, 15.5),
              Offset(16.5, 15.5),
            ]),
            paint,
          );
      case CategoryGlyph.listening:
        canvas
          ..drawPath(
            Path()
              ..moveTo(4, 16)
              ..lineTo(4, 13)
              ..arcTo(
                Rect.fromCircle(center: const Offset(12, 13), radius: 8),
                math.pi,
                math.pi,
                false,
              )
              ..lineTo(20, 16),
            paint,
          )
          ..drawRRect(
            RRect.fromLTRBAndCorners(
              4,
              15,
              7.5,
              21,
              topRight: const Radius.circular(1),
              bottomRight: const Radius.circular(1),
              bottomLeft: const Radius.circular(1),
            ),
            paint,
          )
          ..drawRRect(
            RRect.fromLTRBAndCorners(
              16.5,
              15,
              20,
              21,
              topLeft: const Radius.circular(1),
              bottomLeft: const Radius.circular(1),
              bottomRight: const Radius.circular(1),
            ),
            paint,
          );
    }
    canvas.restore();
  }

  static Path _polyline(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) {
    return oldDelegate.glyph != glyph || oldDelegate.colors != colors;
  }
}
