import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Calcule un itinéraire routier via OSRM.
///
/// L'instance publique sert au développement. En production, injecter
/// [baseUrl] vers l'instance auto-hébergée de l'équipe.
class RouteService {
  RouteService({
    http.Client? client,
    String baseUrl = _defaultBaseUrl,
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  static const String _defaultBaseUrl = 'https://router.project-osrm.org';

  final http.Client _client;
  final String _baseUrl;

  /// Retourne les points de la géométrie, du départ vers l'arrivée.
  ///
  /// Lève une [Exception] si OSRM ne renvoie pas de route exploitable.
  Future<List<LatLng>> getDrivingRoute({
    required LatLng departure,
    required LatLng arrival,
  }) async {
    final Uri uri = Uri.parse(
      '$_baseUrl/route/v1/driving/'
      '${departure.longitude},${departure.latitude};'
      '${arrival.longitude},${arrival.latitude}',
    ).replace(queryParameters: {
      'geometries': 'geojson',
      'overview': 'full',
    });

    final http.Response response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('OSRM : réponse HTTP ${response.statusCode}');
    }

    final Map<String, dynamic> body =
        json.decode(response.body) as Map<String, dynamic>;

    if (body['code'] != 'Ok') {
      throw Exception('OSRM : aucun itinéraire (${body['code']})');
    }

    final List<dynamic> routes = body['routes'] as List<dynamic>;
    if (routes.isEmpty) {
      throw Exception('OSRM : liste de routes vide');
    }

    final Map<String, dynamic> geometry =
        (routes.first as Map<String, dynamic>)['geometry']
            as Map<String, dynamic>;
    final List<dynamic> coordinates =
        geometry['coordinates'] as List<dynamic>;

    // GeoJSON utilise [longitude, latitude] ; LatLng attend (latitude, longitude).
    return coordinates.map((dynamic coordinate) {
      final List<dynamic> pair = coordinate as List<dynamic>;
      return LatLng(
        (pair[1] as num).toDouble(),
        (pair[0] as num).toDouble(),
      );
    }).toList();
  }

  void dispose() => _client.close();
}