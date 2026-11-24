import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/audio/exercise_audio_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../widgets/listen_chip.dart';
import '../widgets/module_screen_layout.dart';

/// Listening reference before the pink-noise drill: the clean noise, then
/// how a boost and a cut sound at every trained frequency. Nothing here is
/// a question, so every example can be heard as often as wanted.
///
/// Pops with `true` when the listener wants to start practising (from
/// "Empezar" or "Omitir"); the back button pops with null.
class PinkIntroScreen extends StatefulWidget {
  const PinkIntroScreen({super.key, this.beforePractice = true});

  /// Opened on the way to the exercises (shows "Omitir" and "Empezar");
  /// otherwise opened from the card just to listen again.
  final bool beforePractice;

  static const _dir = 'assets/eq/eq_pink_noise';
  static const reference = '$_dir/pink_reference_01.wav';

  /// Clean → band → clean examples (the same files the easier levels use).
  static String sweep(int frequency, int gain) {
    final kind = gain > 0 ? 'boost' : 'cut';
    final token = gain > 0 ? 'g$gain' : 'c${-gain}';
    return '$_dir/freq_pink_${kind}_${frequency}_${token}_sweep_01.wav';
  }

  static const frequencies = [125, 250, 500, 1000, 2000, 4000, 8000];

  static String label(int frequency) =>
      frequency >= 1000 ? '${frequency ~/ 1000} kHz' : '$frequency Hz';

  static String region(int frequency) => switch (frequency) {
    125 => 'Subgraves: el peso, el retumbe.',
    250 => 'Graves: cuerpo; en exceso, "embarrado".',
    500 => 'Medios graves: suena a caja o a cartón.',
    1000 => 'Medios: nasal, como a través de un teléfono.',
    2000 => 'Medios agudos: duro, un poco metálico.',
    4000 => 'Presencia: cerca, brillante; en exceso, chillón.',
    _ => 'Aire: brillo fino, como un siseo.',
  };

  @override
  State<PinkIntroScreen> createState() => _PinkIntroScreenState();
}

class _PinkIntroScreenState extends State<PinkIntroScreen> {
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
      debugPrint('PinkIntro: audio inexistente: $path ($error)');
    }
  }

  void _leave() {
    unawaited(_player.stop());
    Navigator.pop(context, true);
  }

  Widget _listen(String label, String path, {bool wide = false}) {
    final snap = _player.snapshot;
    final playing = snap.isPlayingOption(path);
    final active = snap.isActive(path);
    return ListenChip(
      label: label,
      playing: playing,
      progress: active ? snap.progress : 0,
      wide: wide,
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
    Widget frequencies(List<int> list) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final frequency in list) ...[
          _FrequencyRow(
            title: PinkIntroScreen.label(frequency),
            detail: PinkIntroScreen.region(frequency),
            boost: _listen('Realce +9 dB', PinkIntroScreen.sweep(frequency, 9)),
            cut: _listen('Recorte −6 dB', PinkIntroScreen.sweep(frequency, -6)),
          ),
          if (frequency != list.last) const SizedBox(height: 10),
        ],
      ],
    );
    const all = PinkIntroScreen.frequencies;

    return ModuleScreenLayout(
      title: 'Referencia: ruido rosa',
      subtitle:
          'Escucha esto antes de entrenar. Puedes volver aquí cuando quieras desde la tarjeta de Ruido rosa.',
      header: widget.beforePractice
          ? TextButton.icon(
              onPressed: _leave,
              style: TextButton.styleFrom(foregroundColor: AppColors.cyan),
              icon: const Icon(Icons.skip_next_rounded, size: 18),
              label: const Text('Omitir e ir al ejercicio'),
            )
          : null,
      // In two columns: 1 | 2, then the frequencies (low | high).
      children: [
        _Step(
          number: 1,
          title: 'El ruido rosa limpio',
          children: [
            Text(
              'Tiene la misma energía en cada octava: suena parejo, como una cascada. '
              'Es tu punto de partida: memoriza cómo suena sin ningún ajuste.',
              style: caption,
            ),
            const SizedBox(height: 10),
            _listen('Ruido rosa limpio', PinkIntroScreen.reference, wide: true),
          ],
        ),
        _Step(
          number: 2,
          title: 'Lo que vas a responder',
          children: [
            Text(
              'En cada ejercicio hay una sola banda ajustada: una de estas 7 frecuencias, '
              'con un realce de +6 o +9 dB o un recorte de −3 o −6 dB. '
              'Tu respuesta es la frecuencia y el ajuste.',
              style: caption,
            ),
            const SizedBox(height: 6),
            Text(
              'Nivel 1: el ejemplo pasa de limpio a ecualizado y puedes oír el ruido limpio 2 veces. '
              'Nivel 2: el ruido limpio 1 vez. Nivel 3: sin referencia.',
              style: caption,
            ),
          ],
        ),
        _Step(
          number: 3,
          title: 'Así suena cada frecuencia: graves y medios',
          children: [
            Text(
              'Cada ejemplo empieza limpio, sube la banda, se mantiene y vuelve a limpio. '
              'Fíjate en qué cambia. Empieza por los realces: se oyen más fácil que los recortes.',
              style: caption,
            ),
            const SizedBox(height: 12),
            frequencies(all.sublist(0, 4)),
          ],
        ),
        _Step(
          number: 4,
          title: 'Así suena cada frecuencia: medios agudos y agudos',
          children: [frequencies(all.sublist(4))],
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

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.children,
  });

  final int number;
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
            '$number. $title',
            style: AppTypography.cardTitle.copyWith(fontSize: 16, height: 1.25),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _FrequencyRow extends StatelessWidget {
  const _FrequencyRow({
    required this.title,
    required this.detail,
    required this.boost,
    required this.cut,
  });

  final String title;
  final String detail;
  final Widget boost;
  final Widget cut;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$title  ',
                style: AppTypography.cardTitle.copyWith(fontSize: 14),
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
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(child: boost),
            const SizedBox(width: 8),
            Expanded(child: cut),
          ],
        ),
      ],
    );
  }
}
