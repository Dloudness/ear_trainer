import 'package:flutter/material.dart';

import '../../../../core/auth/account_prompt.dart';
import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/cinematic_screen.dart';
import '../../../../core/widgets/premium_back_button.dart';

/// A subscription plan. A null [price] shows "Precio por anunciar" until
/// prices are decided (see CLAUDE.md).
class Plan {
  const Plan({
    required this.id,
    required this.name,
    required this.detail,
    this.price,
    this.badge,
  });

  final String id;
  final String name;
  final String detail;
  final String? price;
  final String? badge;
}

abstract final class Plans {
  /// Fill in the prices here once they are decided.
  static const all = [
    Plan(
      id: 'annual',
      name: 'Anual',
      detail: 'Un pago al año. El mejor precio por mes.',
      badge: 'Mejor precio',
    ),
    Plan(
      id: 'monthly',
      name: 'Mensual',
      detail: 'Pagas mes a mes y cancelas cuando quieras.',
    ),
    Plan(
      id: 'student',
      name: 'Estudiante',
      detail: 'Precio especial con tu correo institucional.',
    ),
  ];

  /// What Premium unlocks, in the listener's words.
  static const benefits = [
    'Todos los niveles: Intermedio y Profesional en Frecuencias, Intervalos y Afinación',
    'Acordes y Diseño sonoro para cine, video y podcast',
    'Seguimiento detallado de tu progreso y recomendaciones',
    'La app se actualiza constantemente: tu suscripción incluye los nuevos ejercicios, áreas y herramientas que vamos sumando',
  ];
}

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  String _selected = Plans.all.first.id;

  void _soon() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Las suscripciones estarán disponibles muy pronto.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _code() async {
    final ok = await promptPremiumCode(context);
    if (ok && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return CinematicScreen(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: CinematicNavBar(backLabel: 'Back'),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.amber,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'EAR TRAINER PREMIUM',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.6,
                      color: AppColors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Entrena todo tu oído,\na tu ritmo.',
                style: AppTypography.display(28).copyWith(
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w500,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 18),
              for (final benefit in Plans.benefits) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppColors.cyan,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        benefit,
                        style: AppTypography.tagline(14).copyWith(
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 14),
              for (final plan in Plans.all) ...[
                _PlanCard(
                  plan: plan,
                  selected: plan.id == _selected,
                  onTap: () => setState(() => _selected = plan.id),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 10),
              _Cta(
                label: MockSession.hasPremium
                    ? 'Ya tienes Premium'
                    : 'Continuar',
                onPressed: MockSession.hasPremium ? null : _soon,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _code,
                  child: const Text('Tengo un código de invitación'),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '¿Eres docente o institución? Habrá licencias para cursos '
                'y universidades.',
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
  });

  final Plan plan;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: plan.name,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: selected
                  ? LinearGradient(
                      colors: [
                        AppColors.cyan.withValues(alpha: 0.18),
                        AppColors.purpleDeep.withValues(alpha: 0.12),
                      ],
                    )
                  : null,
              color: selected ? null : Colors.white.withValues(alpha: 0.035),
              border: Border.all(
                color: selected
                    ? const Color(0xFF67E8F9).withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.1),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? AppColors.cyan
                          : Colors.white.withValues(alpha: 0.3),
                      width: selected ? 6 : 2,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.name,
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (plan.badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: AppColors.amber.withValues(alpha: 0.16),
                                border: Border.all(
                                  color: AppColors.amber.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                plan.badge!,
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.amber,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.detail,
                        style: AppTypography.caption.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  plan.price ?? 'Precio por\nanunciar',
                  textAlign: TextAlign.right,
                  style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    color: plan.price == null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                    fontWeight: plan.price == null
                        ? FontWeight.w400
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Cta extends StatelessWidget {
  const _Cta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: onPressed,
          child: Opacity(
            opacity: enabled ? 1 : 0.6,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(27),
                gradient: const LinearGradient(
                  colors: [AppColors.cyan, AppColors.blue, AppColors.purpleDeep],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blue.withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
