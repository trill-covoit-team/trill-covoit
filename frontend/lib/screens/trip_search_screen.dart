import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/trip_search_provider.dart';
import '../widgets/address_search_field.dart';
import '../widgets/trip_bottom_sheet.dart';
import '../widgets/trip_map_view.dart';

/// Écran principal : carte plein écran, recherche en haut, résultats en bas.
///
/// Architecture : la carte est seule dans un Stack de fond (Positioned.fill),
/// la surcouche UI est une Column (formulaire + Expanded pour le bottom sheet).
/// Ainsi la carte prend toujours 100% de l'écran, avec ou sans résultats.
class TripSearchScreen extends StatelessWidget {
  const TripSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<TripSearchProvider>(
        builder: (context, provider, _) {
          return Stack(
            children: [
              // Fond : la carte, sur toute la surface.
              Positioned.fill(
                child: TripMapView(
                  selectedTrip: provider.selectedTrip,
                  routePoints: provider.routePoints,
                ),
              ),

              // Surcouche : formulaire + zone de résultats.
              Positioned.fill(
                child: SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: _SearchForm(provider: provider),
                      ),
                      // Le bottom sheet vit DANS cette zone : ses pourcentages
                      // sont calculés ici, il ne peut donc jamais recouvrir
                      // le formulaire.
                      Expanded(
                        child: Stack(
                          children: [
                            if (provider.isRouteLoading ||
                                provider.routeErrorMessage != null)
                              Center(
                                child: _RouteStatus(
                                  isLoading: provider.isRouteLoading,
                                  message: provider.routeErrorMessage,
                                ),
                              ),
                            if (provider.trips.isNotEmpty)
                              Positioned.fill(
                                child: TripBottomSheet(
                                  trips: provider.trips,
                                  selectedTrip: provider.selectedTrip,
                                  onTripSelected: provider.selectTrip,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Formulaire de recherche. Aucun état métier ici : tout passe par le provider.
class _SearchForm extends StatelessWidget {
  const _SearchForm({required this.provider});

  final TripSearchProvider provider;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AddressSearchField(
              label: 'Lieu de départ',
              icon: Icons.trip_origin,
              onSelected: (suggestion) => provider.setDeparture(
                suggestion.coordinates,
                suggestion.displayName,
              ),
            ),
            const SizedBox(height: 8),
            AddressSearchField(
              label: "Lieu d'arrivée",
              icon: Icons.flag,
              onSelected: (suggestion) => provider.setArrival(
                suggestion.coordinates,
                suggestion.displayName,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: provider.canSearch && !provider.isLoading
                    ? provider.search
                    : null,
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: const Text('Rechercher'),
              ),
            ),
            if (provider.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                provider.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Retour visuel pendant le calcul de l'itinéraire, ou en cas d'échec.
class _RouteStatus extends StatelessWidget {
  const _RouteStatus({required this.isLoading, this.message});

  final bool isLoading;
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text("Calcul de l'itinéraire…"),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message ?? 'Itinéraire indisponible.',
          style: TextStyle(color: Colors.red.shade900),
        ),
      ),
    );
  }
}