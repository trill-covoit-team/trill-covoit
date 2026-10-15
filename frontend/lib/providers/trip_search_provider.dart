import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/trip.dart';
import '../services/route_service.dart';
import '../services/trip_service.dart';

/// État partagé de la recherche : saisie, résultats et itinéraire sélectionné.
///
/// Le provider orchestre les services. Les widgets ne font que rendre l'état.
class TripSearchProvider extends ChangeNotifier {
  TripSearchProvider({
    required TripService tripService,
    RouteService? routeService,
  })  : _tripService = tripService,
        _routeService = routeService ?? RouteService();

  final TripService _tripService;
  final RouteService _routeService;

  // --- Saisie ---
  LatLng? _departure;
  LatLng? _arrival;
  String? _departureLabel;
  String? _arrivalLabel;
  DateTime? _departureDatetime;

  // --- Résultats ---
  List<Trip> _trips = <Trip>[];
  bool _isLoading = false;
  String? _errorMessage;
  int _searchRequestId = 0;

  // --- Sélection et itinéraire ---
  Trip? _selectedTrip;
  List<LatLng> _routePoints = <LatLng>[];
  bool _isRouteLoading = false;
  String? _routeErrorMessage;

  /// Permet d'ignorer les réponses OSRM arrivant après un nouveau clic.
  int _routeRequestId = 0;

  /// Un trajet déjà calculé ne relance jamais un appel réseau.
  final Map<int, List<LatLng>> _routeCache = <int, List<LatLng>>{};

  // --- Getters ---
  LatLng? get departure => _departure;
  LatLng? get arrival => _arrival;
  String? get departureLabel => _departureLabel;
  String? get arrivalLabel => _arrivalLabel;
  List<Trip> get trips => _trips;
  Trip? get selectedTrip => _selectedTrip;
  List<LatLng> get routePoints => _routePoints;
  bool get isLoading => _isLoading;
  bool get isRouteLoading => _isRouteLoading;
  String? get errorMessage => _errorMessage;
  String? get routeErrorMessage => _routeErrorMessage;

  bool get canSearch => _departure != null && _arrival != null;

  void setDeparture(LatLng coordinates, String label) {
    _departure = coordinates;
    _departureLabel = label;
    notifyListeners();
  }

  void setArrival(LatLng coordinates, String label) {
    _arrival = coordinates;
    _arrivalLabel = label;
    notifyListeners();
  }

  void setDepartureDatetime(DateTime value) {
    _departureDatetime = value;
    notifyListeners();
  }

  /// Lance la recherche. Une recherche plus ancienne est ignorée.
  Future<void> search() async {
    if (!canSearch) return;

    final int requestId = ++_searchRequestId;

    _isLoading = true;
    _errorMessage = null;
    _trips = <Trip>[];
    _resetSelection(notify: false);
    notifyListeners();

    try {
      final List<Trip> results = await _tripService.searchTrips(
        departure: _departure!,
        arrival: _arrival!,
        departureDatetime: _departureDatetime,
      );

      if (requestId != _searchRequestId) return;
      _trips = results;
    } catch (error) {
      if (requestId != _searchRequestId) return;
      _errorMessage = 'Impossible de récupérer les trajets.';
      debugPrint('searchTrips : $error');
    } finally {
      if (requestId == _searchRequestId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Sélectionne un trajet et charge son itinéraire.
  ///
  /// L'ancien tracé est effacé immédiatement : on ne montre jamais l'itinéraire
  /// d'un trajet sous les marqueurs d'un autre.
  Future<void> selectTrip(Trip? trip) async {
    final int requestId = ++_routeRequestId;

    if (trip == null) {
      _resetSelection();
      return;
    }

    _selectedTrip = trip;
    _routeErrorMessage = null;

    final List<LatLng>? cached = _routeCache[trip.tripId];
    if (cached != null) {
      _routePoints = cached;
      _isRouteLoading = false;
      notifyListeners();
      return;
    }

    // Effacement synchrone : le nouvel écran ne montre jamais un tracé périmé.
    _routePoints = <LatLng>[];
    _isRouteLoading = true;
    notifyListeners();

    try {
      final List<LatLng> points = await _routeService
          .getDrivingRoute(
            departure: trip.departureCoordinates,
            arrival: trip.arrivalCoordinates,
          )
          .timeout(const Duration(seconds: 10));

      // Réponse obsolète : l'utilisateur a déjà cliqué ailleurs.
      if (requestId != _routeRequestId) return;

      _routeCache[trip.tripId] = points;
      _routePoints = points;
    } catch (error) {
      if (requestId != _routeRequestId) return;
      _routeErrorMessage = 'Itinéraire indisponible pour le moment.';
      debugPrint('getDrivingRoute : $error');
    } finally {
      if (requestId == _routeRequestId) {
        _isRouteLoading = false;
        notifyListeners();
      }
    }
  }

  void _resetSelection({bool notify = true}) {
    _routeRequestId++;
    _selectedTrip = null;
    _routePoints = <LatLng>[];
    _isRouteLoading = false;
    _routeErrorMessage = null;
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    _routeService.dispose();
    super.dispose();
  }
}