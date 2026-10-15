import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/address_suggestion.dart';

/// Service de géocodage via Nominatim (OpenStreetMap).
///
/// Pour passer à une instance auto-hébergée, il suffit de modifier [_baseUrl].
class GeocodingService {
  const GeocodingService();

  /// URL de l'instance Nominatim.
  /// Instance publique par défaut ; remplacer par l'URL locale en auto-hébergement
  /// (par exemple 'http://10.0.2.2:8080' pour un émulateur Android).
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';

  /// Nominatim exige un User-Agent identifiable.
  static const Map<String, String> _headers = {
    'User-Agent': 'trill-covoit/1.0 (contact@trill-covoit.example)',
    'Accept': 'application/json',
  };

  /// Recherche des adresses correspondant à [query].
  ///
  /// Retourne une liste vide si rien n'est trouvé ou en cas d'erreur réseau.
  Future<List<AddressSuggestion>> searchAddresses(String query) async {
    if (query.trim().length < 3) return [];

    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
      'q': query,
      'format': 'json',
      'limit': '5',
      'addressdetails': '0',
    });

    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) return [];

    final data = json.decode(response.body) as List<dynamic>;
    return data
        .map((item) => AddressSuggestion.fromNominatimJson(
              item as Map<String, dynamic>,
            ))
        .toList();
  }
}