import 'package:latlong2/latlong.dart';

import '../models/trip.dart';

/// Contrat d'accès aux trajets.
///
/// Deux implémentations existent : [HttpTripService] (API réelle) et
/// [MockTripService] (données simulées conformes au contrat, pour le
/// développement en parallèle du backend).
abstract class TripService {
  Future<List<Trip>> searchTrips({
    required LatLng departure,
    required LatLng arrival,
    DateTime? departureDatetime,
    double radiusKm = 5,
    int limit = 20,
  });

  Future<Trip> getTripById(int tripId);
}