import 'dart:async';

import 'package:flutter/material.dart';

import '../router/app_routes.dart';
import '../session/mock_session.dart';
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

/// Gate before any new exercise. Without an account only
/// [MockSession.freeExerciseLimit] exercises are free; after that the
/// visitor must register to go on. Either way they are taken to the home:
/// registered, to their progress; with "Ahora no", to a guest home that
/// shows what they did and invites them to create the (free) account.
/// So this returns false and the caller must not open another exercise nor
/// pop. Returns true only when no gate applies.
Future<bool> ensureCanPractice(BuildContext context) async {
  if (!MockSession.reachedFreeLimit) return true;
  await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _RegisterDialog(freeLimit: true),
  );
  if (context.mounted) {
    unawaited(
      Navigator.of(
        context,
        rootNavigator: true,
      ).pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
    );
  }
  return false;
}

Future<bool> promptPremiumCode(BuildContext context) async {
  final unlocked = await showDialog<bool>(
    context: context,
    builder: (context) => const _PremiumCodeDialog(),
  );
  return unlocked ?? false;
}

class _RegisterDialog extends StatefulWidget {
  const _RegisterDialog({this.freeLimit = false});

  final bool freeLimit;

  @override
  State<_RegisterDialog> createState() => _RegisterDialogState();
}

class _RegisterDialogState extends State<_RegisterDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  String? _nameError;
  String? _emailError;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    setState(() {
      _nameError = name.isEmpty ? 'Escribe tu nombre.' : null;
      _emailError = _emailPattern.hasMatch(email)
          ? null
          : 'Escribe un correo válido.';
    });
    if (_nameError != null || _emailError != null) return;
    await AccountAuth.registerWithMock(name: name, email: email);
    if (mounted) Navigator.pop(context, true);
  }

  InputDecoration _field(String label, String? error) => InputDecoration(
    labelText: label,
    errorText: error,
    isDense: true,
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF12151C),
      title: Text(
        widget.freeLimit
            ? 'Completaste tus ejercicios gratis'
            : 'Sigue entrenando',
        style: AppTypography.cardTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.freeLimit
                  ? 'Crea tu cuenta para seguir entrenando. Te acompañaremos '
                        'con tu progreso: qué vas logrando y qué te conviene reforzar.'
                  : 'Regístrate para continuar con más ejercicios.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              // 16 px or more: smaller text makes iPhone Safari zoom in.
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              decoration: _field('Nombre', _nameError),
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              decoration: _field('Correo', _emailError),
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
              onSubmitted: (_) => _register(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Ahora no'),
        ),
        TextButton(onPressed: _register, child: const Text('Crear cuenta')),
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
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
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
