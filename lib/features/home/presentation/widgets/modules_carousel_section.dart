import 'package:flutter/material.dart';

import '../../../../core/constants/app_module_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/branded_module_icon.dart';
import '../../../../core/widgets/section_header.dart';
import '../../models/training_module.dart';

class ModulesCarouselSection extends StatelessWidget {
  const ModulesCarouselSection({
    super.key,
    required this.modules,
    this.onModuleTap,
    this.onModuleReturn,
  });

  final List<TrainingModule> modules;
  final ValueChanged<TrainingModule>? onModuleTap;
  final VoidCallback? onModuleReturn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Módulos de entrenamiento',
          subtitle: 'Explora y entrena a tu ritmo',
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 228,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: modules.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final module = modules[index];
              return SizedBox(
                width: 172,
                child: ModuleCarouselCard(
                  module: module,
                  onTap: () async {
                    if (module.route != null) {
                      await Navigator.pushNamed(context, module.route!);
                      onModuleReturn?.call();
                    }
                    onModuleTap?.call(module);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ModuleCarouselCard extends StatefulWidget {
  const ModuleCarouselCard({
    super.key,
    required this.module,
    this.onTap,
  });

  final TrainingModule module;
  final VoidCallback? onTap;

  @override
  State<ModuleCarouselCard> createState() => _ModuleCarouselCardState();
}

class _ModuleCarouselCardState extends State<ModuleCarouselCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final module = widget.module;
    final isActive = _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: isActive ? 1.02 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.fromLTRB(15, 18, 15, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isActive
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.035),
              border: Border.all(
                color: isActive
                    ? module.accentStart.withValues(alpha: 0.35)
                    : AppColors.glassBorder,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: module.accentStart.withValues(alpha: 0.12),
                        blurRadius: 20,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BrandedModuleIcon(
                  icon: AppModuleIcons.forIconType(module.iconType),
                  accentStart: module.accentStart,
                  accentEnd: module.accentEnd,
                  isActive: isActive,
                  size: 56,
                  padding: 2,
                ),
                const SizedBox(height: 14),
                Text(module.title, style: AppTypography.cardTitle),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    module.description,
                    style: AppTypography.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: module.progress,
                          minHeight: 3,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          color: module.accentStart,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(module.progress * 100).round()}%',
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
