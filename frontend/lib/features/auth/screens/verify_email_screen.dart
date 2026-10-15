import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:trill_covoit/core/theme/app_theme.dart';
import 'package:trill_covoit/features/auth/providers/auth_provider.dart';
import 'package:trill_covoit/features/auth/screens/login_register_screen.dart';
import 'package:trill_covoit/features/auth/widgets/auth_form_layout.dart';
import 'package:trill_covoit/features/auth/widgets/auth_message.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final success = await auth.verifyEmail(
      email: widget.email,
      code: _codeController.text,
    );
    if (!mounted || !success) return;

    final confirmation = auth.successMessage ?? 'Email validé avec succès.';
    auth.setPendingVerificationEmail(null);
    auth.clearMessages();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LoginRegisterScreen(
          initialLogin: true,
          initialEmail: widget.email,
          confirmationMessage: confirmation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthFormLayout(
      title: "Validation de l'email",
      isBusy: auth.isLoading,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 48),
            const SizedBox(height: 24),
            Text(
              'Vérifiez votre email',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            const Text('Saisissez le code à 6 chiffres envoyé à :'),
            const SizedBox(height: 8),
            Text(widget.email, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            if (auth.successMessage != null)
              AuthMessage(message: auth.successMessage!),
            if (auth.errorMessage != null)
              AuthMessage(message: auth.errorMessage!, isError: true),
            TextFormField(
              key: const ValueKey('verification-code'),
              controller: _codeController,
              enabled: !auth.isLoading,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Code à 6 chiffres',
                hintText: '000000',
                helperText: 'Vous pouvez coller le code reçu par email.',
                helperMaxLines: 2,
                errorMaxLines: 2,
              ),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(letterSpacing: 6),
              validator: (value) {
                if (!RegExp(r'^\d{6}$').hasMatch(value ?? '')) {
                  return 'Veuillez saisir les 6 chiffres du code.';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: auth.isLoading ? null : _submit,
              child: auth.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        semanticsLabel: 'Validation en cours',
                      ),
                    )
                  : const Text('Valider mon email'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Après validation, connectez-vous avec votre mot de passe.',
              style: TextStyle(color: AppTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}
