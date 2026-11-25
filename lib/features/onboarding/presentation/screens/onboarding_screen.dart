import 'package:flutter/material.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/category_icon.dart';
import '../../../../core/widgets/cinematic_screen.dart';
import '../../../../core/widgets/premium_back_button.dart';
import '../../../modules/models/module_exercise_catalog.dart';
import '../../models/onboarding_option.dart';

enum _Profile { all, producer, musician, audiovisual }

extension on _Profile {
  String get label => switch (this) {
    _Profile.all => 'Todos',
    _Profile.producer => 'Productor/a',
    _Profile.musician => 'Músico/a',
    _Profile.audiovisual => 'Audiovisual',
  };

  String get hint => switch (this) {
    _Profile.all => 'Todas las áreas de entrenamiento.',
    _Profile.producer =>
      'Para mezclar mejor: frecuencias, dinámica y diseño sonoro.',
    _Profile.musician => 'Para tocar y cantar con mejor oído.',
    _Profile.audiovisual =>
      'Para cine, video y podcast: frecuencias, dinámica y diseño sonoro.',
  };
}

/// One card on the screen. [option] is null for an area that has no
/// exercises yet.
class _Area {
  const _Area({
    required this.title,
    required this.description,
    required this.glyph,
    required this.colors,
    required this.profiles,
    this.option,
    this.premium = false,
  });

  final OnboardingOption? option;

  /// Needs Premium: without it, opening the area shows the plans.
  final bool premium;
  bool get locked => premium && !MockSession.hasPremium;
  final String title;
  final String description;
  final CategoryGlyph glyph;
  final List<Color> colors;
  final Set<_Profile> profiles;

  bool get comingSoon => option == null;
}

const _areas = [
  _Area(
    option: OnboardingOption.ecualizacionFrecuencias,
    title: 'Frecuencias',
    description: 'Ecualización, ruido rosa y tonos puros.',
    glyph: CategoryGlyph.frequency,
    colors: [Color(0xFFA5F3FC), Color(0xFF3B82F6)],
    profiles: {_Profile.producer, _Profile.musician, _Profile.audiovisual},
  ),
  _Area(
    option: OnboardingOption.dinamicaCompresion,
    title: 'Dinámica',
    description: 'Compresión, punch y control de nivel.',
    glyph: CategoryGlyph.dynamics,
    colors: [Color(0xFFFDE68A), Color(0xFFF97316)],
    profiles: {_Profile.producer, _Profile.audiovisual},
  ),
  _Area(
    option: OnboardingOption.entrenamientoMusical,
    title: 'Musical',
    description: 'Intervalos, acordes y afinación.',
    glyph: CategoryGlyph.musical,
    colors: [Color(0xFFE9D5FF), Color(0xFF7C3AED)],
    profiles: {_Profile.musician},
  ),
  _Area(
    title: 'Diseño sonoro',
    description: 'Sonido para cine, video y podcast.',
    glyph: CategoryGlyph.video,
    colors: [Color(0xFFFED7AA), Color(0xFFEA580C)],
    profiles: {_Profile.audiovisual, _Profile.producer},
    premium: true,
  ),
  // Escucha real is retired: it has no objective exercises.
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  _Profile _profile = _Profile.all;

  Future<void> _open(_Area area) async {
    if (area.locked) {
      await Navigator.pushNamed(context, AppRoutes.plans);
      if (mounted) setState(() {});
      return;
    }
    final option = area.option;
    if (option == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('${area.title} llega pronto.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    await MockSession.setTrainingFocus(option.title);
    if (!mounted) return;
    Navigator.pushNamed(context, ModuleExerciseCatalog.moduleRouteFor(option));
  }

  @override
  Widget build(BuildContext context) {
    final areas = [
      for (final area in _areas)
        if (_profile == _Profile.all || area.profiles.contains(_profile)) area,
    ];

    return CinematicScreen(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: CinematicNavBar(backLabel: 'Back'),
              ),
              Text(
                '¿Qué quieres\nentrenar hoy?',
                style: AppTypography.display(28).copyWith(
                  letterSpacing: 1,
                  fontWeight: FontWeight.w400,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                'SOY…',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.6,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final profile in _Profile.values)
                    _ProfileChip(
                      label: profile.label,
                      selected: profile == _profile,
                      onTap: () => setState(() => _profile = profile),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [...previous, ?current],
                ),
                child: Text(
                  _profile.hint,
                  key: ValueKey(_profile),
                  style: AppTypography.tagline(13).copyWith(
                    color: _profile == _Profile.audiovisual
                        ? const Color(0xFFF9A8D4)
                        : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (final area in areas) ...[
                _AreaCard(area: area, onTap: () => _open(area)),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: selected
                  ? LinearGradient(
                      colors: [
                        AppColors.cyan.withValues(alpha: 0.35),
                        AppColors.purpleDeep.withValues(alpha: 0.35),
                      ],
                    )
                  : null,
              color: selected ? null : Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: selected
                    ? const Color(0xFF67E8F9).withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.12),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.cyan.withValues(alpha: 0.22),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFFCBD5E1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AreaCard extends StatefulWidget {
  const _AreaCard({required this.area, required this.onTap});

  final _Area area;
  final VoidCallback onTap;

  @override
  State<_AreaCard> createState() => _AreaCardState();
}

class _AreaCardState extends State<_AreaCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final area = widget.area;
    final glow = area.colors.last;
    // Premium areas look like the rest (no shading), only a discreet lock.
    final soon = area.comingSoon && !area.locked;
    final lit = _hovered && !soon;

    return Semantics(
      button: true,
      label: area.title,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) => setState(() => _pressed = false),
          onTapCancel: () => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1,
            duration: const Duration(milliseconds: 140),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: lit
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          glow.withValues(alpha: 0.16),
                          Colors.white.withValues(alpha: 0.03),
                        ],
                      )
                    : null,
                color: lit ? null : Colors.white.withValues(alpha: 0.035),
                border: Border.all(
                  color: lit
                      ? area.colors.first.withValues(alpha: 0.55)
                      : Colors.white.withValues(alpha: 0.09),
                ),
                boxShadow: lit
                    ? [
                        BoxShadow(
                          color: glow.withValues(alpha: 0.18),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ]
                    : null,
              ),
              child: Opacity(
                opacity: soon ? 0.75 : 1,
                child: Row(
                  children: [
                    CategoryIcon(
                      glyph: area.glyph,
                      colors: area.colors,
                      lit: lit,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  area.title,
                                  style: AppTypography.cardTitle.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (area.locked) ...[
                                const SizedBox(width: 8),
                                const _Badge(
                                  label: 'Premium',
                                  color: [AppColors.amber, AppColors.amber],
                                  icon: Icons.lock_rounded,
                                ),
                              ] else if (soon) ...[
                                const SizedBox(width: 8),
                                _Badge(label: 'Próximamente', color: area.colors),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            area.description,
                            style: AppTypography.caption.copyWith(fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: lit ? area.colors.first : AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, this.icon});

  final String label;
  final List<Color> color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.last.withValues(alpha: 0.14),
        border: Border.all(color: color.last.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color.first),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color.first,
            ),
          ),
        ],
      ),
    );
  }
}
