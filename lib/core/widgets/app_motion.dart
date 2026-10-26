import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Cinematic fade + micro-slide used across route transitions.
abstract final class AppTransitions {
  static const duration = Duration(milliseconds: 420);
  static const reverseDuration = Duration(milliseconds: 340);

  static Widget build(Animation<double> animation, Widget child) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.88, end: 1).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.012),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }

  static Route<T> cinematicRoute<T>({
    required RouteSettings settings,
    required Widget screen,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, _, _) => screen,
      transitionsBuilder: (_, animation, _, child) => build(animation, child),
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
    );
  }
}

/// Lightweight entrance fade for home sections.
class FadeInSection extends StatefulWidget {
  const FadeInSection({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<FadeInSection> createState() => _FadeInSectionState();
}

class _FadeInSectionState extends State<FadeInSection>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.02),
      end: Offset.zero,
    ).animate(_opacity);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Subtle breathing glow wrapper — one slow animation, opacity only.
class BreathingGlow extends StatefulWidget {
  const BreathingGlow({
    super.key,
    required this.child,
    this.color = AppColors.purple,
    this.minOpacity = 0.08,
    this.maxOpacity = 0.16,
  });

  final Widget child;
  final Color color;
  final double minOpacity;
  final double maxOpacity;

  @override
  State<BreathingGlow> createState() => _BreathingGlowState();
}

class _BreathingGlowState extends State<BreathingGlow>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: widget.minOpacity, end: widget.maxOpacity).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _glow.value),
                blurRadius: 28,
                spreadRadius: -4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
