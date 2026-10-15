import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trill_covoit/core/theme/app_theme.dart';
import 'package:trill_covoit/features/auth/providers/auth_provider.dart';
import 'package:trill_covoit/features/auth/screens/login_register_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  void _openForm(BuildContext context, {required bool initialLogin}) {
    final auth = context.read<AuthProvider>();
    auth.clearMessages();
    auth.setPendingVerificationEmail(null);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LoginRegisterScreen(initialLogin: initialLogin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 440,
                    minHeight: constraints.maxHeight > 48
                        ? constraints.maxHeight - 48
                        : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.directions_car_outlined,
                            size: 48,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(height: 20),
                          Text('TRILL Covoit’', style: textTheme.titleMedium),
                          const SizedBox(height: 32),
                          Text(
                            'Covoiturez sans vous engager',
                            style: textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Partagez vos trajets du quotidien, '
                            'à votre rythme.',
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppTheme.muted,
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _CommunityLabel(
                                icon: Icons.business_outlined,
                                label: 'Entreprise',
                              ),
                              _CommunityLabel(
                                icon: Icons.school_outlined,
                                label: 'École',
                              ),
                              _CommunityLabel(
                                icon: Icons.home_outlined,
                                label: 'Quartier',
                              ),
                            ],
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ElevatedButton(
                              onPressed: () =>
                                  _openForm(context, initialLogin: false),
                              child: const Text("Continuer avec l'email"),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () =>
                                  _openForm(context, initialLogin: true),
                              child: const Text("J'ai déjà un compte"),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CommunityLabel extends StatelessWidget {
  const _CommunityLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
