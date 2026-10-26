import 'dart:math' as math;

class HomeLayoutMetrics {
  const HomeLayoutMetrics({
    required this.scale,
    required this.isWide,
    required this.isDesktop,
    required this.contentWidth,
    required this.horizontalPadding,
    required this.bottomPadding,
  });

  final double scale;
  final bool isWide;
  final bool isDesktop;
  final double contentWidth;
  final double horizontalPadding;
  final double bottomPadding;

  factory HomeLayoutMetrics.fromConstraints({
    required double width,
    required double height,
  }) {
    final isWide = width >= 900;
    final isDesktop = width >= 1200;

    return HomeLayoutMetrics(
      scale: _layoutScale(width),
      isWide: isWide,
      isDesktop: isDesktop,
      contentWidth: math.min(width, isDesktop ? 980.0 : 920.0),
      horizontalPadding: isDesktop ? 40.0 : isWide ? 28.0 : 18.0,
      bottomPadding: math.max(20, height * 0.03),
    );
  }

  static double _layoutScale(double width) {
    if (width >= 1400) return 1.08;
    if (width >= 1100) return 1.0;
    if (width >= 720) return 0.96;
    return 0.9;
  }
}
