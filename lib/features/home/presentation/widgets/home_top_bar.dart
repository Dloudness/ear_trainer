import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/app_language.dart';
import '../painters/mini_waveform_logo_painter.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.language,
    required this.onLanguageChanged,
    this.onProfileTap,
    this.profileLocked = false,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final VoidCallback? onProfileTap;
  final bool profileLocked;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        LanguageSelector(language: language, onChanged: onLanguageChanged),
        const Spacer(),
        if (profileLocked && onProfileTap != null)
          _ProfileLockButton(onTap: onProfileTap!)
        else
          const DiegoLoudnessBadge(),
      ],
    );
  }
}

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({
    super.key,
    required this.language,
    required this.onChanged,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 7, right: 2),
            child: Icon(Icons.language_rounded, size: 14, color: AppColors.textMuted),
          ),
          LangChip(
            label: 'ES',
            selected: language == AppLanguage.es,
            onTap: () => onChanged(AppLanguage.es),
          ),
          Container(
            width: 1,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            color: AppColors.glassBorder,
          ),
          LangChip(
            label: 'EN',
            selected: language == AppLanguage.en,
            onTap: () => onChanged(AppLanguage.en),
          ),
        ],
      ),
    );
  }
}

class LangChip extends StatefulWidget {
  const LangChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<LangChip> createState() => _LangChipState();
}

class _LangChipState extends State<LangChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: widget.selected
                ? AppColors.blue.withValues(alpha: 0.22)
                : _hovered
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.transparent,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.1,
              color: widget.selected ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileLockButton extends StatefulWidget {
  const _ProfileLockButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_ProfileLockButton> createState() => _ProfileLockButtonState();
}

class _ProfileLockButtonState extends State<_ProfileLockButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: _hovered ? AppColors.textPrimary : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.lock_outline_rounded,
                size: 12,
                color: AppColors.purpleLight.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DiegoLoudnessBadge extends StatelessWidget {
  const DiegoLoudnessBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 14,
          height: 12,
          child: CustomPaint(painter: MiniWaveformLogoPainter()),
        ),
        const SizedBox(width: 6),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.3,
              color: AppColors.textMuted,
            ),
            children: [
              const TextSpan(text: 'by '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [AppColors.purpleLight, AppColors.textPrimary],
                  ).createShader(b),
                  child: const Text(
                    'Diego Loudness',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
