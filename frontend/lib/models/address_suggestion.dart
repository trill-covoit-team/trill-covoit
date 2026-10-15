import 'package:latlong2/latlong.dart';

/// Résultat de géocodage : un lieu nommé et ses coordonnées.
class AddressSuggestion {
  final String displayName;
  final LatLng coordinates;

  const AddressSuggestion({
    required this.displayName,
    required this.coordinates,
  });

  factory AddressSuggestion.fromNominatimJson(Map<String, dynamic> json) {
    return AddressSuggestion(
      displayName: json['display_name'] as String,
      coordinates: LatLng(
        double.parse(json['lat'] as String),
        double.parse(json['lon'] as String),
      ),
    );
  }
}