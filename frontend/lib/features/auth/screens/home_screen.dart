import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trill_covoit/features/auth/providers/auth_provider.dart';
import 'package:trill_covoit/features/auth/screens/landing_screen.dart';
import 'package:trill_covoit/features/auth/widgets/auth_form_layout.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AuthProvider>().currentSession;
    if (session == null) return const LandingScreen();

    return AuthFormLayout(
      title: 'TRILL Covoit’',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.check_circle_outline, size: 48),
          const SizedBox(height: 24),
          Text(
            'Bienvenue !',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const Text('Vous êtes connecté avec :'),
          const SizedBox(height: 8),
          Text(
            session.user.email,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => context.read<AuthProvider>().logout(),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}
