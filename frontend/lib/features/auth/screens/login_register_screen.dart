import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:trill_covoit/core/theme/tokens.dart';
import 'package:trill_covoit/features/auth/providers/auth_provider.dart';
import 'package:trill_covoit/features/auth/screens/verify_email_screen.dart';
import 'package:trill_covoit/features/auth/widgets/auth_form_layout.dart';
import 'package:trill_covoit/features/auth/widgets/auth_message.dart';
import 'package:trill_covoit/features/auth/widgets/auth_error_messages.dart';
import 'package:trill_covoit/legal/legal_texts.dart';

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
  String? _emailError;
  String? _bannerError;
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.initialLogin;
    _emailController = TextEditingController(text: widget.initialEmail);
    _confirmationMessage = widget.confirmationMessage;
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _showLegal(privacy: false);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _showLegal(privacy: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
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
      _emailError = null;
      _bannerError = null;
    });
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Veuillez saisir votre email.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Adresse email invalide.';
    }
    return _emailError;
  }

  String? _validatePassword(String? value) {
    if (!_isLogin && (value ?? '').length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères.';
    }
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir votre mot de passe.';
    }
    return null;
  }

  void _openVerification(String email, {String? banner}) {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading) return;
    _passwordController.clear();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => VerifyEmailScreen(email: email, bannerMessage: banner),
      ),
    );
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (auth.isLoading) return;
    _emailError = null;
    _bannerError = null;
    auth.clearMessages();
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
    if (!success && _isLogin && auth.pendingVerificationEmail == email) {
      _openVerification(
        email,
        banner: "Validez votre adresse email pour accéder à l'application.",
      );
    } else if (!success) {
      // Le provider expose les messages, mais ne conserve pas les codes HTTP.
      final message = auth.errorMessage;
      setState(() {
        if (!_isLogin && message == 'Cette adresse email est déjà utilisée.') {
          _emailError = 'Cette adresse email est déjà utilisée.';
        } else if (_isLogin &&
            message == "L'adresse email ou le mot de passe est incorrect.") {
          _bannerError = 'Identifiants invalides';
        } else {
          _bannerError = message != null && AuthErrorMessages.isNetwork(message)
              ? AuthErrorMessages.network
              : AuthErrorMessages.server;
        }
      });
      _formKey.currentState?.validate();
    }
  }

  void _showLegal({required bool privacy}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .85,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        privacy
                            ? LegalTexts.privacyTitle
                            : LegalTexts.termsTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fermer',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.s16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    privacy ? LegalTexts.privacy : LegalTexts.terms,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.isLoading;
    final theme = Theme.of(context);

    return AuthFormLayout(
      title: 'Bienvenue',
      showTitle: false,
      isBusy: isLoading,
      footer: FilledButton(
        onPressed: isLoading ? null : _submit,
        child: isLoading
            ? const SizedBox(
                width: AppSpace.s24,
                height: AppSpace.s24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  semanticsLabel: 'Envoi en cours',
                ),
              )
            : Text(_isLogin ? 'Se connecter' : 'Créer mon compte'),
      ),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text('Bienvenue', style: theme.textTheme.headlineMedium),
              ),
              const SizedBox(height: AppSpace.s24),
              _ModeToggle(
                isLogin: _isLogin,
                isLoading: isLoading,
                onChanged: _switchMode,
              ),
              const SizedBox(height: AppSpace.s24),
              if (_confirmationMessage != null)
                AuthMessage(message: _confirmationMessage!),
              if (_bannerError != null)
                AuthMessage(message: _bannerError!, isError: true),
              TextFormField(
                key: const ValueKey('email'),
                controller: _emailController,
                enabled: !isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                textCapitalization: TextCapitalization.none,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: theme.textTheme.bodyLarge,
                  floatingLabelStyle: theme.textTheme.bodyLarge,
                  hintStyle: theme.textTheme.bodyMedium,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  hintText: 'vous@exemple.fr',
                  errorMaxLines: 3,
                ),
                validator: _validateEmail,
                onChanged: (_) {
                  if (_emailError != null || _bannerError != null) {
                    setState(() {
                      _emailError = null;
                      _bannerError = null;
                    });
                    _formKey.currentState?.validate();
                  }
                  if (auth.pendingVerificationEmail != null) {
                    auth.setPendingVerificationEmail(null);
                    auth.clearMessages();
                  }
                },
              ),
              const SizedBox(height: AppSpace.s24),
              TextFormField(
                key: const ValueKey('password'),
                controller: _passwordController,
                enabled: !isLoading,
                obscureText: _obscurePassword,
                keyboardType: TextInputType.visiblePassword,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                autofillHints: [
                  _isLogin ? AutofillHints.password : AutofillHints.newPassword,
                ],
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  floatingLabelBehavior: FloatingLabelBehavior.always,
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
                onChanged: (_) => setState(() => _bannerError = null),
                onFieldSubmitted: (_) => _submit(),
              ),
              if (!_isLogin) ...[
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.s12),
                  _PasswordStrength(password: _passwordController.text),
                ],
                const SizedBox(height: AppSpace.s16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: kMinTouch,
                      height: kMinTouch,
                      child: Transform.translate(
                        offset: const Offset(0, -AppSpace.s12),
                        child: Checkbox(
                          key: const ValueKey('terms-checkbox'),
                          value: _termsAccepted,
                          activeColor: theme.colorScheme.primary,
                          checkColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          semanticLabel:
                              "Accepter les conditions d'utilisation et la politique de confidentialité",
                          onChanged: isLoading
                              ? null
                              : (value) => setState(() {
                                  _termsAccepted = value ?? false;
                                  if (_termsAccepted) _showTermsError = false;
                                }),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.s4),
                    Expanded(
                      child: RichText(
                        key: const ValueKey('terms-text'),
                        textScaler: MediaQuery.textScalerOf(context),
                        text: TextSpan(
                          style: theme.textTheme.bodyLarge,
                          children: [
                            const TextSpan(text: "J'accepte les "),
                            TextSpan(
                              text: "conditions d'utilisation",
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: isLoading ? null : _termsRecognizer,
                            ),
                            const TextSpan(text: ' et la '),
                            TextSpan(
                              text: 'politique de confidentialité',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: isLoading ? null : _privacyRecognizer,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showTermsError)
                  const AuthMessage(
                    message:
                        'Vous devez accepter les conditions pour continuer.',
                    isError: true,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.isLogin,
    required this.isLoading,
    required this.onChanged,
  });

  final bool isLogin;
  final bool isLoading;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.s4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Inscription',
              selected: !isLogin,
              onPressed: isLoading ? null : () => onChanged(false),
            ),
          ),
          const SizedBox(width: AppSpace.s8),
          Expanded(
            child: _ModeButton(
              label: 'Connexion',
              selected: isLogin,
              onPressed: isLoading ? null : () => onChanged(true),
            ),
          ),
        ],
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
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : AppMotion.fast,
        curve: AppMotion.curve,
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: selected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.s8,
              vertical: AppSpace.s12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.password});

  final String password;

  // Indication visuelle uniquement : la règle d'inscription reste huit caractères.
  int get score {
    if (password.isEmpty) return 0;
    if (password.length < 8) return 1;
    final variety = [
      RegExp('[a-z]'),
      RegExp('[A-Z]'),
      RegExp('[0-9]'),
      RegExp(r'[^a-zA-Z0-9]'),
    ].where((pattern) => pattern.hasMatch(password)).length;
    return variety >= 3 ? 3 : 2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = ['Non renseigné', 'Faible', 'Moyen', 'Robuste'][score];
    return Semantics(
      label: 'Robustesse du mot de passe : $label',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: score / 3,
              minHeight: AppSpace.s4,
              color: theme.colorScheme.primary,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: AppSpace.s8),
          Text('Robustesse : $label', style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }
}
