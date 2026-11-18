import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:trill_covoit/core/constants/api_constants.dart';
import 'package:trill_covoit/core/theme/app_theme.dart';
import 'package:trill_covoit/providers/auth_provider.dart';
import 'package:trill_covoit/screens/landing_screen.dart';
import 'package:trill_covoit/services/api_client.dart';
import 'package:trill_covoit/services/auth_api_service.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key, this.authProvider});

  final AuthProvider? authProvider;

  @override
  Widget build(BuildContext context) {
    if (authProvider != null) {
      return ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider!,
        child: const _MainAppView(),
      );
    }
    return ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(
        apiService: AuthApiService(
          apiClient: ApiClient(
            client: http.Client(),
            baseUrl: ApiConstants.baseUrl,
          ),
        ),
      ),
      child: const _MainAppView(),
    );
  }
}

class _MainAppView extends StatefulWidget {
  const _MainAppView();

  @override
  State<_MainAppView> createState() => _MainAppViewState();
}

class _MainAppViewState extends State<_MainAppView> {
  GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool? _wasAuthenticated;

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.select<AuthProvider, bool>(
      (auth) => auth.isAuthenticated,
    );
    if (_wasAuthenticated != isAuthenticated) {
      _wasAuthenticated = isAuthenticated;
      _navigatorKey = GlobalKey<NavigatorState>();
    }

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'TRILL Covoit’',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const LandingScreen(),
    );
  }
}
