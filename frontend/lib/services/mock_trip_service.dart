import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:latlong2/latlong.dart';

import '../models/trip.dart';
import 'trip_service.dart';

/// Implémentation simulée qui charge les réponses depuis des fichiers JSON
/// dans `assets/mocks/`. Les données respectent strictement le contrat
/// Front/Back et sont réutilisées telles quelles par les tests.
class MockTripService implements TripService {
  static const String _searchResponsePath = 'assets/mocks/trips_search.json';
  static const Duration _simulatedDelay = Duration(milliseconds: 400);

  @override
  Future<List<Trip>> searchTrips({
    required LatLng departure,
    required LatLng arrival,
    DateTime? departureDatetime,
    double radiusKm = 5,
    int limit = 20,
  }) async {
    await Future.delayed(_simulatedDelay);

    final rawJson = await rootBundle.loadString(_searchResponsePath);
    final data = json.decode(rawJson) as List<dynamic>;

    return data
        .map((item) => Trip.fromJson(item as Map<String, dynamic>))
        .take(limit)
        .toList();
  }

  @override
  Future<Trip> getTripById(int tripId) async {
    await Future.delayed(_simulatedDelay);

    final rawJson = await rootBundle.loadString(
      'assets/mocks/trip_detail_$tripId.json',
    );
    return Trip.fromJson(json.decode(rawJson) as Map<String, dynamic>);
  }
}