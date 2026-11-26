import 'package:flutter/material.dart';

import '../../../../core/auth/account_prompt.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/session/mock_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/category_icon.dart';
import '../../../../core/widgets/cinematic_screen.dart';
import '../../../../core/widgets/orb_logo.dart';
import '../../models/mentor.dart';

/// The listener's home: an advisor that follows their progress, says what
/// to reinforce, recognizes what they achieve and offers a tip, instead of
/// game scores.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _go(String route) async {
    await Navigator.pushNamed(context, route);
    if (mounted) setState(() {});
  }

  Future<void> _register() async {
    final ok = await promptRegister(context);
    if (ok && mounted) setState(() {});
  }

  Future<void> _askName() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF12151C),
        title: Text('¿Cómo te llamas?', style: AppTypography.cardTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          // 16 px or more: smaller text makes iPhone Safari zoom in.
          style: AppTypography.caption.copyWith(
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
          decoration: const InputDecoration(labelText: 'Nombre'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty) return;
    await MockSession.setUserName(name);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasAccount = MockSession.hasAccount;
    final advice = MentorAdvice.build();
    final name = MockSession.displayName;

    return CinematicScreen(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Row(
                children: [
                  const OrbLogo(size: 46, animated: false),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isEmpty ? 'Hola' : 'Hola, $name',
                          style: AppTypography.display(24).copyWith(
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Accounts made before the name was asked.
                        if (hasAccount && name.isEmpty)
                          TextButton(
                            onPressed: _askName,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 32),
                              foregroundColor: AppColors.cyan,
                            ),
                            child: const Text('Escribe tu nombre'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              if (hasAccount)
                _MentorCard(
                  headline: advice.headline,
                  message: advice.message,
                  action: advice.action,
                  colors: advice.focus.colors,
                  onAction: () => _go(advice.focus.route),
                )
              else
                _MentorCard(
                  headline: 'Te acompaño en tu proceso',
                  message:
                      'Crea tu cuenta y llevaré tu progreso: lo que vas logrando, '
                      'en qué conviene reforzar y cómo avanzar a tu ritmo.',
                  action: 'Crear mi cuenta',
                  colors: const [Color(0xFFA5F3FC), Color(0xFF7C3AED)],
                  onAction: _register,
                ),
              if (hasAccount && advice.daysThisWeek > 0) ...[
                const SizedBox(height: 12),
                _WeekLine(days: advice.daysThisWeek),
              ],
              const SizedBox(height: 28),
              const _SectionTitle('Cómo va tu oído'),
              const SizedBox(height: 12),
              for (final report in advice.reports) ...[
                _SkillRow(
                  report: report,
                  onTap: () => report.area.locked
                      ? _go(AppRoutes.plans)
                      : _go(report.area.route),
                ),
                const SizedBox(height: 10),
              ],
              if (hasAccount && !MockSession.hasPremium) ...[
                const SizedBox(height: 8),
                _PremiumCard(onTap: () => _go(AppRoutes.plans)),
              ],
              if (hasAccount && advice.praise.isNotEmpty) ...[
                const SizedBox(height: 18),
                const _SectionTitle('Lo que vas logrando'),
                const SizedBox(height: 12),
                for (final line in advice.praise.take(3)) ...[
                  _PraiseLine(text: line),
                  const SizedBox(height: 8),
                ],
              ],
              const SizedBox(height: 18),
              const _SectionTitle('Consejo del día'),
              const SizedBox(height: 12),
              _TipCard(text: advice.tip),
              const SizedBox(height: 24),
              _OutlineButton(
                label: 'Explorar todas las áreas',
                onPressed: () => _go(AppRoutes.onboarding),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.caption.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 1.6,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _MentorCard extends StatelessWidget {
  const _MentorCard({
    required this.headline,
    required this.message,
    required this.action,
    required this.colors,
    required this.onAction,
  });

  final String headline;
  final String message;
  final String action;
  final List<Color> colors;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final glow = colors.last;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            glow.withValues(alpha: 0.22),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(color: colors.first.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: glow.withValues(alpha: 0.18),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: AppTypography.cardTitle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTypography.tagline(14.5).copyWith(
              color: const Color(0xFFCBD5E1),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          _PrimaryButton(label: action, colors: colors, onPressed: onAction),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.colors,
    required this.onPressed,
  });

  final String label;
  final List<Color> colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            height: 50,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: LinearGradient(
                colors: [colors.last, AppColors.purpleDeep],
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.last.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekLine extends StatelessWidget {
  const _WeekLine({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < days
                  ? AppColors.cyan
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
        ],
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            days == 1
                ? 'Practicaste 1 día esta semana.'
                : 'Practicaste $days días esta semana.',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.report, required this.onTap});

  final SkillReport report;
  final VoidCallback onTap;

  Color get _statusColor => switch (report.status) {
    'Sólido' => const Color(0xFF34D399),
    'En progreso' => AppColors.cyan,
    'Por reforzar' => const Color(0xFFFBBF24),
    _ => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final area = report.area;
    final level = report.levelReached;
    final locked = area.locked;
    final detail = locked
        ? 'Disponible con Premium.'
        : !report.started
        ? 'Aún no lo has practicado.'
        : !report.enough
        ? 'Haz unos ejercicios más para ver tu avance.'
        : 'Aciertas ${report.outOfTen} de cada 10'
              '${level == null ? '' : ' · Nivel $level'}.';

    return Semantics(
      button: true,
      label: area.title,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.035),
              border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
            ),
            child: Row(
              children: [
                CategoryIcon(glyph: area.glyph, colors: area.colors, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              area.title,
                              style: AppTypography.cardTitle.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (locked)
                            const _PremiumChip()
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: _statusColor.withValues(alpha: 0.14),
                                border: Border.all(
                                  color: _statusColor.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                report.status,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if (report.enough) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: report.ratio,
                            minHeight: 5,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            valueColor: AlwaysStoppedAnimation(
                              area.colors.last,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        detail,
                        style: AppTypography.caption.copyWith(fontSize: 12),
                      ),
                    ],
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

class _PremiumChip extends StatelessWidget {
  const _PremiumChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.amber.withValues(alpha: 0.14),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 11, color: AppColors.amber),
          SizedBox(width: 4),
          Text(
            'Premium',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.amber,
            ),
          ),
        ],
      ),
    );
  }
}

/// Invitation to the subscription, shown to accounts without Premium.
class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ver planes Premium',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.amber.withValues(alpha: 0.16),
                  AppColors.purpleDeep.withValues(alpha: 0.12),
                ],
              ),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    color: AppColors.amber.withValues(alpha: 0.18),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lleva tu oído más lejos',
                        style: AppTypography.cardTitle.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Todos los niveles, Acordes, Diseño sonoro y todo lo nuevo: la app se actualiza constantemente.',
                        style: AppTypography.caption.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Ver planes',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.amber,
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

class _PraiseLine extends StatelessWidget {
  const _PraiseLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: Color(0xFF34D399),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTypography.tagline(14).copyWith(
              color: AppColors.textPrimary,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.035),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 20,
            color: AppColors.amber,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.tagline(14).copyWith(
                color: const Color(0xFFCBD5E1),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFFE2E8F0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
