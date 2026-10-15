import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/trip.dart';

/// Rendu géographique : marqueurs et polyligne de l'itinéraire sélectionné.
///
/// Les points sont fournis par le provider, qui gère le chargement, le cache
/// et l'invalidation des réponses obsolètes. Ce widget ne fait aucun appel réseau.
class TripMapView extends StatefulWidget {
  const TripMapView({
    super.key,
    this.selectedTrip,
    this.routePoints = const <LatLng>[],
  });

  final Trip? selectedTrip;
  final List<LatLng> routePoints;

  @override
  State<TripMapView> createState() => _TripMapViewState();
}

class _TripMapViewState extends State<TripMapView> {
  /// Centre de secours tant qu'aucun trajet n'est sélectionné.
  static const LatLng _defaultCenter = LatLng(43.6045, 1.4442);
  static const double _tripZoom = 12;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    // Le MapController n'est attaché à la carte qu'après le premier build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _centerOnSelectedTrip();
    });
  }

  @override
  void didUpdateWidget(covariant TripMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTrip?.tripId != oldWidget.selectedTrip?.tripId) {
      _centerOnSelectedTrip();
    }
  }

  void _centerOnSelectedTrip() {
    final Trip? trip = widget.selectedTrip;
    if (trip == null) return;

    final LatLng departure = trip.departureCoordinates;
    final LatLng arrival = trip.arrivalCoordinates;

    // On cadre le milieu du trajet : pour les trajets du quotidien, les deux
    // extrémités restent visibles à ce niveau de zoom.
    _mapController.move(
      LatLng(
        (departure.latitude + arrival.latitude) / 2,
        (departure.longitude + arrival.longitude) / 2,
      ),
      _tripZoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Trip? trip = widget.selectedTrip;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: trip?.departureCoordinates ?? _defaultCenter,
        initialZoom: 12,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.trill.covoit',
        ),

        // L'itinéraire est dessiné sous les marqueurs.
        if (widget.routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.routePoints,
                strokeWidth: 5,
                color: Colors.blue,
                borderStrokeWidth: 2,
                borderColor: Colors.blue.shade900,
              ),
            ],
          ),

        // Un seul trajet à la fois : celui que l'utilisateur a choisi.
        if (trip != null)
          MarkerLayer(
            markers: [
              Marker(
                point: trip.departureCoordinates,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.green,
                  size: 36,
                ),
              ),
              Marker(
                point: trip.arrivalCoordinates,
                width: 40,
                height: 40,
                child: const Icon(Icons.flag, color: Colors.red, size: 32),
              ),
            ],
          ),
      ],
    );
  }
}