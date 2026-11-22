import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../audio/exercise_audio_player.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// One clip the orb can play (A, B, reference, processed…).
class OrbSource {
  const OrbSource({required this.id, required this.tab, required this.title});

  final String id;

  /// Short text in the A | B switch.
  final String tab;

  /// Name shown under the orb while this clip is selected.
  final String title;
}

/// Premium listening control: one large play button inside a glass disc,
/// a gradient ring that fills with playback and an A/B switch below.
class OrbPlayer extends StatefulWidget {
  const OrbPlayer({
    super.key,
    required this.sources,
    required this.selectedId,
    required this.onSelect,
    required this.isPlaying,
    required this.isPaused,
    required this.progress,
    required this.onPlayPause,
    this.position,
    this.duration,
    this.listensUsed,
    this.enabled = true,
  });

  final List<OrbSource> sources;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final bool isPlaying;
  final bool isPaused;
  final double progress;
  final VoidCallback onPlayPause;
  final Duration? position;
  final Duration? duration;

  /// Listens spent on the selected clip, out of 3. Null hides the counter.
  final int? listensUsed;
  final bool enabled;

  @override
  State<OrbPlayer> createState() => _OrbPlayerState();
}

class _OrbPlayerState extends State<OrbPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant OrbPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPlaying != widget.isPlaying) _syncPulse();
  }

  void _syncPulse() {
    if (widget.isPlaying) {
      _pulse.repeat();
    } else {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  OrbSource get _selected => widget.sources.firstWhere(
    (source) => source.id == widget.selectedId,
    orElse: () => widget.sources.first,
  );

  String get _status {
    final duration = widget.duration;
    if (duration != null && duration > Duration.zero) {
      return '${_clock(widget.position ?? Duration.zero)} / ${_clock(duration)}';
    }
    if (widget.isPlaying) return 'Reproduciendo…';
    if (widget.isPaused) return 'Pausado';
    return 'Listo para escuchar';
  }

  static String _clock(Duration value) {
    final seconds = value.inSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = MediaQuery.sizeOf(context).height;
        final size = math.min(
          math.min(240.0, constraints.maxWidth * 0.62),
          screenHeight * 0.24,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOrb(size),
            const SizedBox(height: 14),
            Text(
              _selected.title,
              style: AppTypography.cardTitle.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _status,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (widget.sources.length > 1) ...[
              const SizedBox(height: 18),
              _OrbSwitch(
                sources: widget.sources,
                selectedId: _selected.id,
                onSelect: widget.onSelect,
              ),
            ],
            if (widget.listensUsed != null) ...[
              const SizedBox(height: 14),
              _ListenPills(used: widget.listensUsed!),
            ],
          ],
        );
      },
    );
  }

  Widget _buildOrb(double size) {
    final disc = size * 0.77;
    final button = size * 0.37;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              if (!widget.isPlaying) return const SizedBox.shrink();
              final t = _pulse.value;
              return Opacity(
                opacity: (0.55 * (1 - t)).clamp(0.0, 1.0),
                child: Container(
                  width: disc * (0.8 + 0.45 * t),
                  height: disc * (0.8 + 0.45 * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cyan, width: 2),
                  ),
                ),
              );
            },
          ),
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(progress: widget.progress),
          ),
          Container(
            width: disc,
            height: disc,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.3, -0.4),
                colors: [
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
                  blurRadius: 50,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
          ),
          _PlayButton(
            size: button,
            isPlaying: widget.isPlaying,
            enabled: widget.enabled,
            onTap: widget.onPlayPause,
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatefulWidget {
  const _PlayButton({
    required this.size,
    required this.isPlaying,
    required this.enabled,
    required this.onTap,
  });

  final double size;
  final bool isPlaying;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<_PlayButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return Semantics(
      button: true,
      label: widget.isPlaying ? 'Pausar' : 'Reproducir',
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: enabled ? widget.onTap : null,
          child: AnimatedScale(
            scale: _pressed ? 0.94 : 1,
            duration: const Duration(milliseconds: 140),
            child: AnimatedOpacity(
              opacity: enabled ? 1 : 0.4,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.cyan, AppColors.blue, AppColors.purpleDeep],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: 0.10),
                      spreadRadius: 6,
                    ),
                    BoxShadow(
                      color: AppColors.cyan.withValues(
                        alpha: widget.isPlaying ? 0.45 : 0.32,
                      ),
                      blurRadius: 40,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    widget.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    key: ValueKey(widget.isPlaying),
                    color: Colors.white,
                    size: widget.size * 0.46,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 5.0;
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

    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    if (sweep <= 0) return;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [
            Color(0xFF67E8F9),
            AppColors.blue,
            AppColors.purple,
            Color(0xFF67E8F9),
          ],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _OrbSwitch extends StatelessWidget {
  const _OrbSwitch({
    required this.sources,
    required this.selectedId,
    required this.onSelect,
  });

  final List<OrbSource> sources;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final index = math.max(
      0,
      sources.indexWhere((source) => source.id == selectedId),
    );
    final count = sources.length;
    final wide = sources.any((source) => source.tab.length > 2);

    return Container(
      width: wide ? 280 : 220,
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            alignment: Alignment(
              count == 1 ? 0 : -1 + 2 * index / (count - 1),
              0,
            ),
            child: FractionallySizedBox(
              widthFactor: 1 / count,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cyan.withValues(alpha: 0.35),
                      AppColors.purpleDeep.withValues(alpha: 0.35),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF67E8F9).withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final source in sources)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: source.id == selectedId,
                    label: source.title,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelect(source.id),
                        child: Center(
                          child: Text(
                            source.tab,
                            style: TextStyle(
                              fontSize: wide ? 13 : 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: wide ? 0.4 : 0,
                              color: source.id == selectedId
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListenPills extends StatelessWidget {
  const _ListenPills({required this.used});

  final int used;

  @override
  Widget build(BuildContext context) {
    const max = ExerciseAudioPlayer.maxListens;
    final left = (max - used).clamp(0, max);
    final label = switch (left) {
      0 => 'Sin escuchas',
      1 => 'Queda 1 escucha',
      _ => 'Quedan $left escuchas',
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: 22,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: i < used ? Colors.white.withValues(alpha: 0.12) : null,
              gradient: i < used
                  ? null
                  : const LinearGradient(
                      colors: [AppColors.cyan, AppColors.blue],
                    ),
            ),
          ),
        ],
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
