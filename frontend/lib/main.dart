import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'providers/trip_search_provider.dart';
import 'screens/trip_search_screen.dart';
import 'services/http_trip_service.dart';
import 'services/mock_trip_service.dart';
import 'services/trip_service.dart';

/// Lit la valeur de --dart-define=USE_MOCK=true au lancement.
/// Par défaut : true, pour que `flutter run` fonctionne sans backend.
const bool useMockData =
bool.fromEnvironment('USE_MOCK', defaultValue: true);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');

  // Sélection de l'implémentation selon la configuration de build.
  final TripService tripService =
  useMockData ? MockTripService() : HttpTripService();

  runApp(TrillCovoitApp(tripService: tripService));
}

class TrillCovoitApp extends StatelessWidget {
  final TripService tripService;

  const TrillCovoitApp({super.key, required this.tripService});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TripSearchProvider(tripService: tripService),
      child: MaterialApp(
        title: 'TRILL Covoit\'',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr', 'FR')],
        home: const TripSearchScreen(),
      ),
    );
  }
}