import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/training_module.dart';
import 'module_neon_icon.dart';

class ModuleCardsRow extends StatelessWidget {
  const ModuleCardsRow({
    super.key,
    required this.modules,
    required this.isWide,
  });

  final List<TrainingModule> modules;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < modules.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: ModuleCard(module: modules[i])),
            ],
          ],
        ),
      );
    }

    return SizedBox(
      height: 218,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: modules.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) => SizedBox(
          width: 168,
          child: ModuleCard(module: modules[i]),
        ),
      ),
    );
  }
}

class ModuleCard extends StatefulWidget {
  const ModuleCard({super.key, required this.module});

  final TrainingModule module;

  @override
  State<ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<ModuleCard> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isActive = _hovered || _pressed;
    final accent = widget.module.accentStart;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: () {},
        child: AnimatedScale(
          scale: isActive ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(15, 18, 15, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isActive
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.035),
              border: Border.all(
                color: isActive ? accent.withValues(alpha: 0.35) : AppColors.glassBorder,
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                if (isActive)
                  BoxShadow(
                    color: accent.withValues(alpha: 0.12),
                    blurRadius: 20,
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModuleNeonIcon(
                  type: widget.module.iconType,
                  accentStart: widget.module.accentStart,
                  accentEnd: widget.module.accentEnd,
                  isActive: isActive,
                ),
                const SizedBox(height: 14),
                Text(widget.module.title, style: AppTypography.cardTitle),
                const SizedBox(height: 7),
                Container(
                  height: 1,
                  width: 24,
                  color: accent.withValues(alpha: 0.45),
                ),
                const SizedBox(height: 7),
                Expanded(
                  child: Text(
                    widget.module.description,
                    style: AppTypography.caption,
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

class PaginationDots extends StatelessWidget {
  const PaginationDots({super.key, required this.activeIndex});

  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i == activeIndex;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 7 : 5,
          height: active ? 7 : 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.blue : AppColors.textMuted.withValues(alpha: 0.35),
          ),
        );
      }),
    );
  }
}
