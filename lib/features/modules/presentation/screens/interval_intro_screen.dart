import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/audio/exercise_audio_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../widgets/listen_chip.dart';
import '../widgets/module_screen_layout.dart';

/// Listening reference before the interval drill: every interval on piano,
/// rising, falling and with both notes together, grouped by level.
///
/// Pops with `true` when the listener wants to start practising (from
/// "Empezar" or "Omitir"); the back button pops with null.
class IntervalIntroScreen extends StatefulWidget {
  const IntervalIntroScreen({super.key, this.beforePractice = true});

  final bool beforePractice;

  static const _dir = 'assets/musical/intervalos_referencia';

  static String clip(String kind, String mode) =>
      '$_dir/interval_ref_${kind}_$mode.wav';

  static const modes = {'asc': 'Sube', 'desc': 'Baja', 'harm': 'Juntas'};

  /// (id, name, what it sounds like), by level.
  static const groups = [
    (
      'Básico',
      [
        ('min2', '2da menor · 1 semitono', 'La distancia más pequeña: roza.'),
        ('maj3', '3ra mayor · 4 semitonos', 'El brillo del acorde mayor.'),
        ('perf4', '4ta justa · 5 semitonos', 'Abierta, un poco suspendida.'),
        ('perf5', '5ta justa · 7 semitonos', 'Hueca y estable.'),
        ('perf8', 'Octava · 12 semitonos', 'La misma nota en otro registro.'),
      ],
    ),
    (
      'Intermedio: el resto de la octava',
      [
        ('maj2', '2da mayor · 2 semitonos', 'Un paso de escala, un tono.'),
        ('min3', '3ra menor · 3 semitonos', 'El color del acorde menor.'),
        (
          'tritone',
          'Tritono · 6 semitonos',
          'Parte la octava a la mitad: tenso.',
        ),
        ('min6', '6ta menor · 8 semitonos', 'Ancha, con un dejo nostálgico.'),
        ('maj6', '6ta mayor · 9 semitonos', 'Abierta y luminosa.'),
        ('min7', '7ma menor · 10 semitonos', 'A un tono de la octava.'),
        ('maj7', '7ma mayor · 11 semitonos', 'A un semitono de la octava.'),
      ],
    ),
    (
      'Profesional: más allá de la octava',
      [
        ('min9', '9na menor · 13 semitonos', 'Octava + 2da menor.'),
        ('maj9', '9na mayor · 14 semitonos', 'Octava + 2da mayor.'),
        ('min10', '10ma menor · 15 semitonos', 'Octava + 3ra menor.'),
        ('maj10', '10ma mayor · 16 semitonos', 'Octava + 3ra mayor.'),
      ],
    ),
  ];

  @override
  State<IntervalIntroScreen> createState() => _IntervalIntroScreenState();
}

class _IntervalIntroScreenState extends State<IntervalIntroScreen> {
  final ExerciseAudioPlayer _player = ExerciseAudioPlayer();

  @override
  void initState() {
    super.initState();
    _player.onPlaybackStateChanged = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play(String path) async {
    try {
      await _player.playOption(path, path);
    } catch (error) {
      debugPrint('IntervalIntro: audio inexistente: $path ($error)');
    }
  }

  void _leave() {
    unawaited(_player.stop());
    Navigator.pop(context, true);
  }

  Widget _listen(String label, String path) {
    final snap = _player.snapshot;
    return ListenChip(
      label: label,
      playing: snap.isPlayingOption(path),
      progress: snap.isActive(path) ? snap.progress : 0,
      onTap: () => unawaited(_play(path)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final caption = AppTypography.caption.copyWith(
      fontSize: 12,
      height: 1.4,
      color: AppColors.textSecondary,
    );
    return ModuleScreenLayout(
      title: 'Referencia: intervalos',
      subtitle:
          'Escucha esto antes de entrenar. Puedes volver aquí cuando quieras desde la tarjeta de Intervalos.',
      header: widget.beforePractice
          ? TextButton.icon(
              onPressed: _leave,
              style: TextButton.styleFrom(foregroundColor: AppColors.cyan),
              icon: const Icon(Icons.skip_next_rounded, size: 18),
              label: const Text('Omitir e ir al ejercicio'),
            )
          : null,
      // In two columns: what an interval is | what you answer, then levels.
      children: [
        _Card(
          title: '¿Qué es un intervalo?',
          children: [
            Text(
              'Es la distancia entre dos notas, medida en semitonos. Puede sonar '
              'subiendo (ascendente), bajando (descendente) o con las dos notas a la vez (armónico). '
              'Aquí todos los ejemplos son de piano y parten de Do.',
              style: caption,
            ),
          ],
        ),
        _Card(
          title: 'Lo que vas a responder',
          children: [
            Text(
              'Escuchas dos notas y eliges el intervalo. En los ejercicios cambian la nota de partida '
              'y el instrumento (piano o guitarra): lo que se repite es la distancia.',
              style: caption,
            ),
            const SizedBox(height: 6),
            Text(
              'Básico: 5 intervalos muy distintos, subiendo y bajando. Intermedio: los 12 de la octava, '
              'también juntos. Profesional: suma los que pasan la octava y las opciones se parecen más.',
              style: caption,
            ),
          ],
        ),
        for (final (title, intervals) in IntervalIntroScreen.groups)
          _Card(
            title: title,
            children: [
              for (final (kind, name, detail) in intervals) ...[
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$name  ',
                        style: AppTypography.cardTitle.copyWith(fontSize: 14),
                      ),
                      TextSpan(text: detail, style: caption),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final mode in IntervalIntroScreen.modes.entries) ...[
                      if (mode.key != 'asc') const SizedBox(width: 6),
                      Expanded(
                        child: _listen(
                          mode.value,
                          IntervalIntroScreen.clip(kind, mode.key),
                        ),
                      ),
                    ],
                  ],
                ),
                if (kind != intervals.last.$1) const SizedBox(height: 10),
              ],
            ],
          ),
        if (widget.beforePractice)
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              label: 'EMPEZAR A ENTRENAR',
              icon: Icons.play_arrow_rounded,
              emphasized: true,
              onPressed: _leave,
            ),
          ),
      ],
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
