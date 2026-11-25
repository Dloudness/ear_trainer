import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/audio/exercise_audio_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../../models/practice_levels.dart';
import '../widgets/module_screen_layout.dart';

/// Guided listening reference for the interval drill: one track per level
/// (tools/generate_intervals.dart) with every interval of that level, from
/// small to large. Nothing plays until the listener presses play; while it
/// plays, the name of the interval that sounds lights up.
///
/// Pops with `true` when the listener wants to start practising (from
/// "Empezar" or "Omitir"); the back button pops with null.
class IntervalIntroScreen extends StatefulWidget {
  const IntervalIntroScreen({
    super.key,
    this.beforePractice = true,
    this.level = 1,
  });

  /// Opened on the way to the exercises (shows "Omitir" and "Empezar").
  final bool beforePractice;

  /// Level whose guide is shown first.
  final int level;

  static const _dir = 'assets/musical/intervalos_referencia';
  static const cuesPath = 'assets/data/interval_reference.json';

  /// Single interval on piano (kept for other screens and checks).
  static String clip(String kind, String mode) =>
      '$_dir/interval_ref_${kind}_$mode.m4a';

  static const modes = {'asc': 'Sube', 'desc': 'Baja', 'harm': 'Juntas'};

  /// What each interval sounds like.
  static const character = {
    'min2': 'La distancia más pequeña: roza.',
    'maj2': 'Un paso de escala, un tono.',
    'min3': 'El color del acorde menor.',
    'maj3': 'El brillo del acorde mayor.',
    'perf4': 'Abierta, un poco suspendida.',
    'tritone': 'Parte la octava a la mitad: tenso.',
    'perf5': 'Hueca y estable.',
    'min6': 'Ancha, con un dejo nostálgico.',
    'maj6': 'Abierta y luminosa.',
    'min7': 'A un tono de la octava.',
    'maj7': 'A un semitono de la octava.',
    'perf8': 'La misma nota en otro registro.',
    'min9': 'Octava + 2da menor.',
    'maj9': 'Octava + 2da mayor.',
    'min10': 'Octava + 3ra menor.',
    'maj10': 'Octava + 3ra mayor.',
  };

  @override
  State<IntervalIntroScreen> createState() => _IntervalIntroScreenState();
}

class GuideCue {
  const GuideCue(
    this.start,
    this.end,
    this.interval,
    this.mode,
    this.label,
    this.semitones,
  );

  final double start, end;
  final String interval, mode, label;
  final int semitones;
}

class GuideTrack {
  const GuideTrack(this.level, this.audio, this.seconds, this.cues);

  final int level;
  final String audio;
  final double seconds;
  final List<GuideCue> cues;

  static List<GuideTrack> parse(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    return [
      for (final t in (data['tracks'] as List).cast<Map<String, dynamic>>())
        GuideTrack(
          t['level'] as int,
          t['audio'] as String,
          (t['seconds'] as num).toDouble(),
          [
            for (final c in (t['cues'] as List).cast<Map<String, dynamic>>())
              GuideCue(
                (c['start'] as num).toDouble(),
                (c['end'] as num).toDouble(),
                c['interval'] as String,
                c['mode'] as String,
                c['label'] as String,
                c['semitones'] as int,
              ),
          ],
        ),
    ];
  }

  /// Cue sounding (or just sounded) at [seconds]; null before the first.
  GuideCue? at(double seconds) {
    GuideCue? current;
    for (final cue in cues) {
      if (cue.start <= seconds + 0.05) current = cue;
    }
    return current;
  }

  /// Intervals in order, each with the directions it sounds in.
  List<(String, String, int, List<String>)> get intervals {
    final out = <(String, String, int, List<String>)>[];
    for (final cue in cues) {
      if (out.isNotEmpty && out.last.$1 == cue.interval) {
        out.last.$4.add(cue.mode);
      } else {
        out.add((cue.interval, cue.label, cue.semitones, [cue.mode]));
      }
    }
    return out;
  }
}

class _IntervalIntroScreenState extends State<IntervalIntroScreen> {
  final ExerciseAudioPlayer _player = ExerciseAudioPlayer();
  static const _slot = 'guide';

  List<GuideTrack> _tracks = const [];
  late int _level = widget.level;

  @override
  void initState() {
    super.initState();
    _player.onPlaybackStateChanged = () {
      if (mounted) setState(() {});
    };
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final tracks = GuideTrack.parse(
        await rootBundle.loadString(IntervalIntroScreen.cuesPath),
      );
      if (mounted) setState(() => _tracks = tracks);
    } catch (error) {
      debugPrint('IntervalIntro: no se pudo leer la referencia ($error)');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  GuideTrack? get _track {
    for (final t in _tracks) {
      if (t.level == _level) return t;
    }
    return _tracks.isEmpty ? null : _tracks.first;
  }

  Future<void> _toggle(GuideTrack track) async {
    try {
      await _player.playOption(_slot, track.audio);
    } catch (error) {
      debugPrint('IntervalIntro: audio inexistente: ${track.audio} ($error)');
    }
  }

  Future<void> _selectLevel(int level) async {
    if (level == _level) return;
    await _player.stop();
    if (mounted) setState(() => _level = level);
  }

  void _leave() {
    unawaited(_player.stop());
    Navigator.pop(context, true);
  }

  String _time(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final caption = AppTypography.caption.copyWith(
      fontSize: 12,
      height: 1.4,
      color: AppColors.textSecondary,
    );
    final track = _track;
    final snap = _player.snapshot;
    final active = snap.isActive(_slot);
    final playing = snap.isPlayingOption(_slot);
    final seconds = active ? snap.position.inMilliseconds / 1000 : -1.0;
    final current = active ? track?.at(seconds) : null;
    const ladder = LevelLadder.intervals;

    return ModuleScreenLayout(
      title: 'Referencia: intervalos',
      subtitle:
          'Escúchala antes de practicar. Puedes volver aquí cuando quieras desde la tarjeta de Intervalos.',
      header: widget.beforePractice
          ? TextButton.icon(
              onPressed: _leave,
              style: TextButton.styleFrom(foregroundColor: AppColors.cyan),
              icon: const Icon(Icons.skip_next_rounded, size: 18),
              label: const Text('Omitir e ir al ejercicio'),
            )
          : null,
      // In two columns: player | now playing, then the list.
      children: [
        _Card(
          title: 'Escucha la referencia',
          children: [
            Text(
              'Cada intervalo suena de menor a mayor, en piano desde Do, y su nombre se '
              'ilumina mientras suena. Nada suena hasta que le des play; puedes pausar cuando quieras.',
              style: caption,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var level = 1; level <= ladder.maxLevel; level++)
                  if (ladder.canPlay(level))
                    ChoiceChip(
                      label: Text(ladder.name(level)),
                      selected: level == _level,
                      onSelected: (_) => unawaited(_selectLevel(level)),
                    ),
              ],
            ),
            const SizedBox(height: 12),
            if (track != null) ...[
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: playing
                      ? 'PAUSAR'
                      : snap.isPausedOption(_slot)
                      ? 'CONTINUAR'
                      : 'ESCUCHAR',
                  icon: playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  emphasized: true,
                  onPressed: () => unawaited(_toggle(track)),
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: active ? snap.progress : 0,
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  color: AppColors.cyan,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                active
                    ? '${_time(snap.position)} / ${_time(snap.duration)}'
                    : '${track.cues.length} ejemplos · ${(track.seconds / 60).ceil()} min',
                style: caption,
              ),
            ],
          ],
        ),
        _Card(
          title: 'Ahora suena',
          children: [
            Text(
              current == null ? '—' : current.label,
              style: AppTypography.display(28).copyWith(
                color: current == null
                    ? AppColors.textSecondary
                    : AppColors.cyan,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              current == null
                  ? 'Dale play para empezar.'
                  : '${IntervalIntroScreen.modes[current.mode]} · '
                        '${current.semitones} semitono${current.semitones == 1 ? '' : 's'} · '
                        '${IntervalIntroScreen.character[current.interval] ?? ''}',
              style: caption,
            ),
          ],
        ),
        if (track != null)
          _Card(
            title: 'Intervalos de ${ladder.name(track.level)}',
            children: [
              for (final (kind, label, semis, modes) in track.intervals)
                _IntervalRow(
                  label: label,
                  semitones: semis,
                  detail: IntervalIntroScreen.character[kind] ?? '',
                  modes: modes,
                  activeMode: current?.interval == kind ? current!.mode : null,
                ),
            ],
          ),
        if (widget.beforePractice)
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              label: 'EMPEZAR A ENTRENAR',
              icon: Icons.play_arrow_rounded,
              onPressed: _leave,
            ),
          ),
      ],
    );
  }
}

class _IntervalRow extends StatelessWidget {
  const _IntervalRow({
    required this.label,
    required this.semitones,
    required this.detail,
    required this.modes,
    this.activeMode,
  });

  final String label, detail;
  final int semitones;
  final List<String> modes;

  /// Direction sounding now, when this interval is the one sounding.
  final String? activeMode;

  @override
  Widget build(BuildContext context) {
    final on = activeMode != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: on ? AppColors.cyan.withValues(alpha: 0.12) : null,
        border: Border.all(
          color: on
              ? AppColors.cyan
              : AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$label · $semitones  ',
                    style: AppTypography.cardTitle.copyWith(
                      fontSize: 14,
                      color: on ? AppColors.cyan : null,
                    ),
                  ),
                  TextSpan(
                    text: detail,
                    style: AppTypography.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          for (final mode in modes) ...[
            const SizedBox(width: 6),
            Text(
              IntervalIntroScreen.modes[mode]!,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                color: mode == activeMode
                    ? AppColors.cyan
                    : AppColors.textSecondary.withValues(alpha: 0.6),
                fontWeight: mode == activeMode ? FontWeight.w700 : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      accent: AppColors.cyan,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.cardTitle.copyWith(fontSize: 16, height: 1.25),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}
