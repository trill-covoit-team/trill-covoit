import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trill_covoit/core/theme/tokens.dart';
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
      title: 'Tableau de bord',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Bonjour,', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpace.s8),
          Text(
            session.user.email,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpace.s32),
          OutlinedButton(
            onPressed: () => context.read<AuthProvider>().logout(),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}
