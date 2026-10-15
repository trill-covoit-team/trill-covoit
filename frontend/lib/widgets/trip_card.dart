import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/trip.dart';

/// Carte compacte résumant un trajet dans la liste.
class TripCard extends StatelessWidget {
  final Trip trip;
  final bool isSelected;
  final VoidCallback onTap;

  const TripCard({
    super.key,
    required this.trip,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('EEEE d MMMM, HH:mm', 'fr_FR');
    
    // Sécurisation : évite RangeError si le prénom est vide.
    final firstName = trip.driver.firstName.trim();
    final initial = firstName.isNotEmpty ? firstName.substring(0, 1).toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: isSelected ? Colors.blue.shade50 : null,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(initial),
        ),
        title: Text(
          '${trip.departureAddress} → ${trip.arrivalAddress}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(timeFormat.format(trip.departureDatetime.toLocal())),
            Text(
              '${trip.driver.firstName} ${trip.driver.lastName} · '
              '${trip.vehicle.brand} ${trip.vehicle.model} · '
              '${trip.offeredSeats} place(s)',
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }
}