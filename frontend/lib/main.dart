import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trill_covoit/core/theme/app_theme.dart';
import 'package:trill_covoit/features/auth/providers/auth_provider.dart';
import 'package:trill_covoit/features/auth/screens/home_screen.dart';
import 'package:trill_covoit/features/auth/screens/landing_screen.dart';

import 'core/theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool? _wasAuthenticated;

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.select<AuthProvider, bool>(
      (auth) => auth.isAuthenticated,
    );
    if (_wasAuthenticated != isAuthenticated) {
      _wasAuthenticated = isAuthenticated;
      // Une nouvelle session repart sans les anciennes routes.
      _navigatorKey = GlobalKey<NavigatorState>();
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'TRILL Covoit’',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: isAuthenticated ? const HomeScreen() : const LandingScreen(),
    );
  }
}
