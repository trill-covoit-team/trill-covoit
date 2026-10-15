import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/trip.dart';
import 'trip_service.dart';

/// Implémentation réelle : appelle l'API backend Spring Boot.
class HttpTripService implements TripService {
  /// URL de l'API backend.
  /// Sur émulateur Android : 10.0.2.2 correspond à localhost de l'hôte.
  static const String _baseUrl = 'http://10.0.2.2:8080';

  @override
  Future<List<Trip>> searchTrips({
    required LatLng departure,
    required LatLng arrival,
    DateTime? departureDatetime,
    double radiusKm = 5,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$_baseUrl/trips').replace(queryParameters: {
      'departureLat': departure.latitude.toString(),
      'departureLng': departure.longitude.toString(),
      'arrivalLat': arrival.latitude.toString(),
      'arrivalLng': arrival.longitude.toString(),
      if (departureDatetime != null)
        'departureDatetime': departureDatetime.toUtc().toIso8601String(),
      'radiusKm': radiusKm.toString(),
      'limit': limit.toString(),
    });

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la recherche de trajets '
          '(HTTP ${response.statusCode})');
    }

    final data = json.decode(response.body) as List<dynamic>;
    return data
        .map((item) => Trip.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Trip> getTripById(int tripId) async {
    final response = await http.get(Uri.parse('$_baseUrl/trips/$tripId'));
    if (response.statusCode != 200) {
      throw Exception('Trajet introuvable (HTTP ${response.statusCode})');
    }
    return Trip.fromJson(json.decode(response.body) as Map<String, dynamic>);
  }
}