import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'account_auth.dart';

Future<bool> promptRegister(BuildContext context) async {
  final registered = await showDialog<bool>(
    context: context,
    builder: (context) => const _RegisterDialog(),
  );
  return registered ?? false;
}

Future<bool> promptPremiumCode(BuildContext context) async {
  final unlocked = await showDialog<bool>(
    context: context,
    builder: (context) => const _PremiumCodeDialog(),
  );
  return unlocked ?? false;
}

class _RegisterDialog extends StatelessWidget {
  const _RegisterDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF12151C),
      title: Text('Sigue entrenando', style: AppTypography.cardTitle),
      content: Text(
        'Regístrate para continuar con más ejercicios.',
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Ahora no'),
        ),
        TextButton(
          onPressed: () async {
            await AccountAuth.registerWithMock();
            if (context.mounted) Navigator.pop(context, true);
          },
          child: const Text('Registrarme'),
        ),
      ],
    );
  }
}

class _PremiumCodeDialog extends StatefulWidget {
  const _PremiumCodeDialog();

  @override
  State<_PremiumCodeDialog> createState() => _PremiumCodeDialogState();
}

class _PremiumCodeDialogState extends State<_PremiumCodeDialog> {
  final TextEditingController _code = TextEditingController();
  var _invalid = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF12151C),
      title: Text('Premium', style: AppTypography.cardTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acordes e inversiones se desbloquean con un código de invitación.',
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _code,
            style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Código',
              errorText: _invalid ? 'Código no válido.' : null,
            ),
            onSubmitted: (_) => _redeem(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cerrar'),
        ),
        TextButton(
          onPressed: _redeem,
          child: const Text('Canjear'),
        ),
      ],
    );
  }

  Future<void> _redeem() async {
    final ok = await AccountAuth.redeemInvite(_code.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _invalid = true);
  }
}
