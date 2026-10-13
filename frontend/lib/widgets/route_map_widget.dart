import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Widget qui affiche une carte OpenStreetMap et, si des coordonnées de départ
/// et d'arrivée sont fournies, trace l'itinéraire via OSRM.
class RouteMapWidget extends StatefulWidget {
  /// Coordonnée de départ (obligatoire pour afficher la carte).
  final LatLng startPoint;

  /// Coordonnée d'arrivée (optionnelle). Si null, seul le point de départ
  /// est affiché.
  final LatLng? endPoint;

  const RouteMapWidget({
    super.key,
    required this.startPoint,
    this.endPoint,
  });

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  /// Liste des points qui composent l'itinéraire (polyligne).
  List<LatLng> _routePoints = [];

  /// Indique si l'itinéraire est en cours de chargement.
  bool _isLoadingRoute = false;

  /// Message d'erreur éventuel à afficher.
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Si une destination est fournie, on demande l'itinéraire dès l'ouverture.
    if (widget.endPoint != null) {
      _fetchRoute();
    }
  }

  /// Appelle l'API OSRM pour calculer l'itinéraire entre le départ et l'arrivée.
  ///
  /// OSRM est un moteur de routage open-source. L'instance publique
  /// `router.project-osrm.org` est gratuite et ne nécessite pas de clé API.
  /// Pour la production, il est recommandé d'héberger sa propre instance.
  Future<void> _fetchRoute() async {
    final endPoint = widget.endPoint;
    if (endPoint == null) return;

    setState(() {
      _isLoadingRoute = true;
      _errorMessage = null;
    });

    try {
      // Construction de l'URL de l'API OSRM (format GeoJSON).
      final url = Uri.parse(
        'http://router.project-osrm.org/route/v1/driving/'
            '${widget.startPoint.longitude},${widget.startPoint.latitude};'
            '${endPoint.longitude},${endPoint.latitude}'
            '?geometries=geojson&overview=full',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // OSRM renvoie les coordonnées au format [longitude, latitude].
        final List<dynamic> coordinates =
        data['routes'][0]['geometry']['coordinates'];

        // Conversion en LatLng (latitude, longitude).
        final routePoints = coordinates
            .map((coord) => LatLng(coord[1] as double, coord[0] as double))
            .toList();

        setState(() {
          _routePoints = routePoints;
          _isLoadingRoute = false;
        });
      } else {
        setState(() {
          _isLoadingRoute = false;
          _errorMessage = 'Impossible de calculer l\'itinéraire. '
              'Code HTTP : ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingRoute = false;
        _errorMessage = 'Erreur lors du calcul de l\'itinéraire : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ---- Carte OpenStreetMap ----
        FlutterMap(
          options: MapOptions(
            // Centrage initial sur le point de départ.
            initialCenter: widget.startPoint,
            initialZoom: 14,
            // Permet à l'utilisateur de déplacer et zoomer librement.
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // Couche de tuiles OpenStreetMap (gratuite, sans clé API).
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.trill.covoit', // À adapter
            ),

            // ---- Marqueurs ----
            MarkerLayer(
              markers: [
                // Marqueur du point de départ.
                Marker(
                  point: widget.startPoint,
                  width: 40,
                  height: 40,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.green,
                    size: 40,
                  ),
                ),
                // Marqueur d'arrivée (si présent).
                if (widget.endPoint != null)
                  Marker(
                    point: widget.endPoint!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.flag,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
              ],
            ),

            // ---- Polyligne de l'itinéraire ----
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 5.0,
                    color: Colors.blue.withOpacity(0.8),
                    borderStrokeWidth: 2.0,
                    borderColor: Colors.blue.shade900,
                  ),
                ],
              ),
          ],
        ),

        // ---- Indicateur de chargement ----
        if (_isLoadingRoute)
          const Center(
            child: CircularProgressIndicator(),
          ),

        // ---- Message d'erreur ----
        if (_errorMessage != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}