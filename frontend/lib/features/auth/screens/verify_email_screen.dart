import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trill_covoit/core/theme/tokens.dart';
import 'package:trill_covoit/features/auth/providers/auth_provider.dart';
import 'package:trill_covoit/features/auth/screens/login_register_screen.dart';
import 'package:trill_covoit/features/auth/widgets/auth_error_messages.dart';
import 'package:trill_covoit/features/auth/widgets/auth_form_layout.dart';
import 'package:trill_covoit/features/auth/widgets/auth_message.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.email, this.bannerMessage});

  final String email;
  final String? bannerMessage;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with SingleTickerProviderStateMixin {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  late final AnimationController _shake;
  bool _verified = false;
  bool _submitting = false;
  bool _resettingCode = false;
  bool _invalidCode = false;
  bool _showInitialBanner = true;
  String? _error;

  String get _code => _controllers.map((controller) => controller.text).join();

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(vsync: this, duration: AppMotion.fast);
    for (var i = 0; i < _focusNodes.length; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          _controllers[i].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controllers[i].text.length,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _openAuth() {
    final auth = context.read<AuthProvider>();
    if (_submitting || _resettingCode || auth.isLoading) return;
    if (_verified) auth.setPendingVerificationEmail(null);
    auth.clearMessages();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LoginRegisterScreen(
          initialLogin: true,
          initialEmail: widget.email,
          confirmationMessage: _verified ? 'Adresse email validée' : null,
        ),
      ),
    );
  }

  void _changed(int index, String value) {
    if (_submitting || _resettingCode || _verified) return;
    setState(() {
      _error = null;
      _invalidCode = false;
      _showInitialBanner = false;
    });
    if (value.length > 1) {
      // Un code collé ou proposé par le système remplit les cases en une fois.
      final start = value.length >= 6 ? 0 : index;
      final digits = value.substring(0, math.min(value.length, 6 - start));
      for (var i = start; i < 6; i++) {
        _controllers[i].text = i - start < digits.length
            ? digits[i - start]
            : '';
      }
      final next = math.min(start + digits.length, 5);
      _focusNodes[next].requestFocus();
    } else if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_controllers.every((controller) => controller.text.length == 1)) {
      _submit();
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (_verified || _submitting || _resettingCode || auth.isLoading) return;
    if (!RegExp(r'^\d{6}$').hasMatch(_code)) {
      setState(() => _error = 'Veuillez saisir les 6 chiffres du code.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
      _invalidCode = false;
      _showInitialBanner = false;
    });
    FocusScope.of(context).unfocus();
    final success = await auth.verifyEmail(email: widget.email, code: _code);
    if (!mounted) return;
    final message = auth.errorMessage ?? AuthErrorMessages.server;
    setState(() {
      _submitting = false;
      _verified = success;
      if (!success) {
        _invalidCode = AuthErrorMessages.isInvalidCode(message);
        _resettingCode = _invalidCode;
        _error = _invalidCode
            ? 'Code invalide. Réessayez.'
            : AuthErrorMessages.isNetwork(message)
            ? AuthErrorMessages.network
            : AuthErrorMessages.server;
      }
    });
    if (_invalidCode) {
      if (!MediaQuery.disableAnimationsOf(context)) {
        try {
          await _shake.forward(from: 0).orCancel;
        } on TickerCanceled {
          return;
        }
      }
      if (!mounted) return;
      // Effacer uniquement le code refusé, une fois le retour visuel terminé.
      for (final controller in _controllers) {
        controller.clear();
      }
      setState(() => _resettingCode = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNodes.first.requestFocus();
      });
    }
  }

  Widget _digit(int index, ThemeData theme) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(
        color: _invalidCode
            ? theme.colorScheme.error
            : theme.colorScheme.outline,
      ),
    );
    return SizedBox(
      width: kMinTouch,
      child: Focus(
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _controllers[index].text.isEmpty &&
              index > 0) {
            _focusNodes[index - 1].requestFocus();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          key: ValueKey(
            index == 0 ? 'verification-code' : 'verification-digit-$index',
          ),
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          enabled: !_submitting && !_resettingCode,
          keyboardType: TextInputType.number,
          textInputAction: index == 5
              ? TextInputAction.done
              : TextInputAction.next,
          autofillHints: const [AutofillHints.oneTimeCode],
          autocorrect: false,
          enableSuggestions: false,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            color: _invalidCode
                ? theme.colorScheme.error
                : theme.colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            // Le libellé sémantique reste distinct pour chacune des six cases.
            hintText: '–',
            border: border,
            enabledBorder: border,
            disabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: BorderSide(
                color: _invalidCode
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ),
            constraints: const BoxConstraints(minHeight: kMinTouch),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s4,
              vertical: AppSpace.s12,
            ),
          ),
          onChanged: (value) => _changed(index, value),
          onSubmitted: (_) => _submit(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = _submitting || context.watch<AuthProvider>().isLoading;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !busy && !_resettingCode) _openAuth();
      },
      child: AuthFormLayout(
        title: 'Vérifiez votre email',
        showTitle: false,
        isBusy: busy,
        onBack: _openAuth,
        footer: FilledButton(
          onPressed: busy || _resettingCode
              ? null
              : _verified
              ? _openAuth
              : _submit,
          child: busy
              ? const SizedBox(
                  width: AppSpace.s24,
                  height: AppSpace.s24,
                  child: CircularProgressIndicator(
                    strokeWidth: AppSpace.s4,
                    semanticsLabel: 'Validation en cours',
                  ),
                )
              : Text(_verified ? 'Se connecter' : 'Valider mon email'),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                'Vérifiez votre email',
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: AppSpace.s16),
            Text('Le code a été envoyé à :', style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppSpace.s8),
            Text(widget.email, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpace.s24),
            if (_showInitialBanner && widget.bannerMessage != null)
              AuthMessage(message: widget.bannerMessage!),
            if (_verified) ...[
              Semantics(
                liveRegion: true,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppMotion.fast,
                  builder: (_, value, child) =>
                      Transform.scale(scale: value, child: child),
                  child: Icon(
                    Icons.check_circle,
                    size: AppSpace.s48,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.s16),
              const AuthMessage(message: 'Adresse email validée'),
            ] else ...[
              AutofillGroup(
                child: AnimatedBuilder(
                  animation: _shake,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(
                      math.sin(_shake.value * math.pi * 6) *
                          AppSpace.s8 *
                          (1 - _shake.value),
                      0,
                    ),
                    child: child,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpace.s8,
                    runSpacing: AppSpace.s12,
                    children: List.generate(
                      6,
                      (index) => Semantics(
                        label: 'Chiffre ${index + 1} sur 6',
                        child: _digit(index, theme),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.s12),
              Text(
                'Vous pouvez coller le code reçu par email.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpace.s16),
              if (_error != null) AuthMessage(message: _error!, isError: true),
              const TextButton(
                onPressed: null,
                child: Text('Renvoyer le code'),
              ),
              Text(
                'Le renvoi du code est indisponible pour le moment.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
