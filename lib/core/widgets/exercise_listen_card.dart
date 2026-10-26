import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/option_choice_palette.dart';

/// Premium A/B listen card with play/pause control and scrubbable waveform.
class ExerciseListenCard extends StatefulWidget {
  const ExerciseListenCard({
    super.key,
    required this.slot,
    required this.label,
    required this.isPlaying,
    required this.isPaused,
    required this.progress,
    required this.onPlayPause,
    required this.onSeek,
    this.onReplay,
    this.pulse,
  });

  final OptionSlot slot;
  final String label;
  final bool isPlaying;
  final bool isPaused;
  final double progress;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onSeek;
  final VoidCallback? onReplay;
  final Animation<double>? pulse;

  @override
  State<ExerciseListenCard> createState() => _ExerciseListenCardState();
}

class _ExerciseListenCardState extends State<ExerciseListenCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  late final AnimationController _playIconController;
  final GlobalKey _waveformKey = GlobalKey();

  OptionChoiceColors get _colors => OptionChoiceColors.forSlot(widget.slot);

  bool get _active => widget.isPlaying || widget.isPaused || _hovered;

  bool get _showReplay =>
      !widget.isPlaying && !widget.isPaused && widget.progress > 0.99;

  @override
  void initState() {
    super.initState();
    _playIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _syncPlayIcon();
  }

  @override
  void didUpdateWidget(covariant ExerciseListenCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying ||
        oldWidget.isPaused != widget.isPaused) {
      _syncPlayIcon();
    }
  }

  void _syncPlayIcon() {
    if (widget.isPlaying) {
      _playIconController.forward();
    } else {
      _playIconController.reverse();
    }
  }

  @override
  void dispose() {
    _playIconController.dispose();
    super.dispose();
  }

  void _handleScrub(double localX, double width) {
    if (width <= 0) return;
    widget.onSeek((localX / width).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 160),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Color.alphaBlend(
              colors.tint.withValues(alpha: _active ? 0.65 : 0.42),
              Colors.white.withValues(alpha: 0.03),
            ),
            border: Border.all(
              color: colors.accent.withValues(alpha: _active ? 0.45 : 0.26),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: colors.glow.withValues(alpha: widget.isPlaying ? 0.2 : 0.08),
                blurRadius: widget.isPlaying ? 22 : 16,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ListenPlayButton(
                    colors: colors,
                    isPlaying: widget.isPlaying,
                    showReplay: _showReplay,
                    pressed: _pressed,
                    playIconAnimation: _playIconController,
                    onTapDown: () => setState(() => _pressed = true),
                    onTapUp: () => setState(() => _pressed = false),
                    onTapCancel: () => setState(() => _pressed = false),
                    onTap: _showReplay && widget.onReplay != null
                        ? widget.onReplay!
                        : widget.onPlayPause,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _ListenBadge(colors: colors, active: _active),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.label,
                                style: AppTypography.cardTitle.copyWith(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.isPlaying
                              ? 'Reproduciendo…'
                              : widget.isPaused
                                  ? 'Pausado'
                                  : _showReplay
                                      ? 'Toca para repetir'
                                      : 'Listo para escuchar',
                          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              GestureDetector(
                key: _waveformKey,
                behavior: HitTestBehavior.opaque,
                onTapDown: (details) {
                  final box =
                      _waveformKey.currentContext?.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  final local = box.globalToLocal(details.globalPosition);
                  _handleScrub(local.dx, box.size.width);
                },
                onHorizontalDragUpdate: (details) {
                  final box =
                      _waveformKey.currentContext?.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  final local = box.globalToLocal(details.globalPosition);
                  _handleScrub(local.dx, box.size.width);
                },
                child: _ListenWaveformProgress(
                  color: colors.accent,
                  glow: colors.glow,
                  progress: widget.progress,
                  isPlaying: widget.isPlaying,
                  pulse: widget.pulse,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListenPlayButton extends StatelessWidget {
  const _ListenPlayButton({
    required this.colors,
    required this.isPlaying,
    required this.showReplay,
    required this.pressed,
    required this.playIconAnimation,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    required this.onTap,
  });

  final OptionChoiceColors colors;
  final bool isPlaying;
  final bool showReplay;
  final bool pressed;
  final Animation<double> playIconAnimation;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTapUp(),
      onTapCancel: onTapCancel,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.tint.withValues(alpha: isPlaying ? 0.9 : 0.65),
          border: Border.all(
            color: colors.accent.withValues(alpha: isPlaying ? 0.55 : 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.glow.withValues(alpha: isPlaying ? 0.22 : 0.1),
              blurRadius: isPlaying ? 18 : 12,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: playIconAnimation,
            builder: (context, child) {
              if (showReplay) {
                return Icon(Icons.replay_rounded, color: colors.accent, size: 24);
              }
              return Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 1 - playIconAnimation.value,
                    child: Icon(Icons.play_arrow_rounded, color: colors.accent, size: 26),
                  ),
                  Opacity(
                    opacity: playIconAnimation.value,
                    child: Icon(Icons.pause_rounded, color: colors.accent, size: 24),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ListenBadge extends StatelessWidget {
  const _ListenBadge({required this.colors, required this.active});

  final OptionChoiceColors colors;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.tint.withValues(alpha: active ? 0.85 : 0.55),
        border: Border.all(color: colors.accent.withValues(alpha: active ? 0.55 : 0.32)),
      ),
      alignment: Alignment.center,
      child: Text(
        colors.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: colors.accent.withValues(alpha: active ? 1 : 0.75),
        ),
      ),
    );
  }
}

class _ListenWaveformProgress extends StatelessWidget {
  const _ListenWaveformProgress({
    required this.color,
    required this.glow,
    required this.progress,
    required this.isPlaying,
    this.pulse,
  });

  final Color color;
  final Color glow;
  final double progress;
  final bool isPlaying;
  final Animation<double>? pulse;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: pulse ?? const AlwaysStoppedAnimation(0),
        builder: (context, _) {
          return CustomPaint(
            painter: _ListenWaveformProgressPainter(
              color: color,
              glow: glow,
              progress: progress,
              isPlaying: isPlaying,
              pulsePhase: pulse?.value ?? 0,
            ),
          );
        },
      ),
    );
  }
}

class _ListenWaveformProgressPainter extends CustomPainter {
  _ListenWaveformProgressPainter({
    required this.color,
    required this.glow,
    required this.progress,
    required this.isPlaying,
    required this.pulsePhase,
  });

  final Color color;
  final Color glow;
  final double progress;
  final bool isPlaying;
  final double pulsePhase;

  static const _heights = [
    0.28, 0.52, 0.38, 0.72, 0.46, 0.88, 0.54, 0.68, 0.42, 0.76, 0.36, 0.58,
    0.64, 0.44, 0.82, 0.5, 0.7, 0.4, 0.6, 0.48,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final barCount = _heights.length;
    final gap = size.width / barCount;
    final playheadX = size.width * progress;

    for (var i = 0; i < barCount; i++) {
      final x = i * gap + gap * 0.5;
      final played = x <= playheadX;
      final pulseBoost = isPlaying ? (0.06 * pulsePhase) : 0;
      final h = _heights[i] * (played ? 1.0 + pulseBoost : 0.55);
      final paint = Paint()
        ..color = color.withValues(alpha: played ? 0.88 : 0.22)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x, size.height),
        Offset(x, size.height * (1 - h)),
        paint,
      );
    }

    final headPaint = Paint()
      ..color = glow.withValues(alpha: isPlaying ? 0.55 : 0.35)
      ..strokeWidth = 1.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    canvas.drawLine(
      Offset(playheadX, 2),
      Offset(playheadX, size.height - 2),
      headPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ListenWaveformProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.pulsePhase != pulsePhase ||
        oldDelegate.color != color;
  }
}
