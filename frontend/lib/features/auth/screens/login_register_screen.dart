import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trill_covoit/core/theme/app_theme.dart';
import 'package:trill_covoit/features/auth/providers/auth_provider.dart';
import 'package:trill_covoit/features/auth/screens/verify_email_screen.dart';
import 'package:trill_covoit/features/auth/widgets/auth_form_layout.dart';
import 'package:trill_covoit/features/auth/widgets/auth_message.dart';

class LoginRegisterScreen extends StatefulWidget {
  const LoginRegisterScreen({
    super.key,
    this.initialLogin = false,
    this.initialEmail = '',
    this.confirmationMessage,
  });

  final bool initialLogin;
  final String initialEmail;
  final String? confirmationMessage;

  @override
  State<LoginRegisterScreen> createState() => _LoginRegisterScreenState();
}

class _LoginRegisterScreenState extends State<LoginRegisterScreen> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  late bool _isLogin;
  late String? _confirmationMessage;
  bool _obscurePassword = true;
  bool _termsAccepted = false;
  bool _showTermsError = false;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialLogin;
    _emailController = TextEditingController(text: widget.initialEmail);
    _confirmationMessage = widget.confirmationMessage;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchMode(bool isLogin) {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading || _isLogin == isLogin) return;
    auth.clearMessages();
    auth.setPendingVerificationEmail(null);
    setState(() {
      _isLogin = isLogin;
      _formKey = GlobalKey<FormState>();
      _passwordController.clear();
      _obscurePassword = true;
      _termsAccepted = false;
      _showTermsError = false;
      _confirmationMessage = null;
    });
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Veuillez saisir votre email.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Veuillez saisir un email valide.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir votre mot de passe.';
    }
    if (!_isLogin && value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères.';
    }
    return null;
  }

  void _openVerification(String email) {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading) return;
    _passwordController.clear();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => VerifyEmailScreen(email: email)),
    );
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading) return;
    final isValid = _formKey.currentState!.validate();
    setState(() {
      _showTermsError = !_isLogin && !_termsAccepted;
      _confirmationMessage = null;
    });
    if (!isValid || _showTermsError) return;

    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    // Ne pas réutiliser l'email d'une ancienne tentative refusée.
    auth.setPendingVerificationEmail(null);
    final success = _isLogin
        ? await auth.login(email: email, password: _passwordController.text)
        : await auth.register(
            email: email,
            password: _passwordController.text,
            termsAccepted: _termsAccepted,
          );
    if (!mounted) return;
    if (success && !_isLogin) _openVerification(email);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.isLoading;
    final pendingEmail = auth.pendingVerificationEmail;

    return AuthFormLayout(
      title: _isLogin ? 'Connexion' : 'Inscription',
      isBusy: isLoading,
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ModeButton(
                      label: 'Inscription',
                      selected: !_isLogin,
                      onPressed: isLoading ? null : () => _switchMode(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModeButton(
                      label: 'Connexion',
                      selected: _isLogin,
                      onPressed: isLoading ? null : () => _switchMode(true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                _isLogin ? 'Bon retour' : 'Créez votre compte',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? 'Connectez-vous pour retrouver vos trajets.'
                    : 'Un email, un mot de passe, et vous voilà prêt.',
                style: const TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 24),
              if (_confirmationMessage != null)
                AuthMessage(message: _confirmationMessage!),
              if (auth.errorMessage != null)
                AuthMessage(message: auth.errorMessage!, isError: true),
              TextFormField(
                key: const ValueKey('email'),
                controller: _emailController,
                enabled: !isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'vous@exemple.fr',
                ),
                validator: _validateEmail,
                onChanged: (_) {
                  if (auth.pendingVerificationEmail != null) {
                    auth.setPendingVerificationEmail(null);
                    auth.clearMessages();
                  }
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                key: const ValueKey('password'),
                controller: _passwordController,
                enabled: !isLoading,
                obscureText: _obscurePassword,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                autofillHints: [
                  _isLogin ? AutofillHints.password : AutofillHints.newPassword,
                ],
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  helperText: _isLogin ? null : 'Au moins 8 caractères',
                  helperMaxLines: 2,
                  errorMaxLines: 3,
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Afficher le mot de passe'
                        : 'Masquer le mot de passe',
                    onPressed: isLoading
                        ? null
                        : () => setState(() {
                            _obscurePassword = !_obscurePassword;
                          }),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
                validator: _validatePassword,
                onFieldSubmitted: (_) => _submit(),
              ),
              if (!_isLogin) ...[
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _termsAccepted,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text("J'accepte les conditions d'utilisation"),
                  onChanged: isLoading
                      ? null
                      : (value) => setState(() {
                          _termsAccepted = value ?? false;
                          if (_termsAccepted) _showTermsError = false;
                        }),
                ),
                if (_showTermsError)
                  const AuthMessage(
                    message: "Veuillez accepter les conditions d'utilisation.",
                    isError: true,
                  ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          semanticsLabel: 'Envoi en cours',
                        ),
                      )
                    : Text(_isLogin ? 'Se connecter' : "S'inscrire"),
              ),
              if (_isLogin && pendingEmail != null) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () => _openVerification(pendingEmail),
                  child: const Text('Valider mon email'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: selected
          ? ElevatedButton(onPressed: onPressed, child: Text(label))
          : OutlinedButton(onPressed: onPressed, child: Text(label)),
    );
  }
}
