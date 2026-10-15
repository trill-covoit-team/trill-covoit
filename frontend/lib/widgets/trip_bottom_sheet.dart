import 'package:flutter/material.dart';

import '../models/trip.dart';
import 'trip_card.dart';

/// Panneau de résultats : liste défilable, redimensionnable et toujours
/// récupérable après réduction.
///
/// Trois états : déployé (90%), replié au minimum (20%), masqué derrière une pill.
/// La poignée est branchée à un DraggableScrollableController avec gestes
/// onTap et onVerticalDragEnd. minChildSize = 0.2 (jamais 0, la poignée reste
/// toujours saisissable).
class TripBottomSheet extends StatefulWidget {
  const TripBottomSheet({
    super.key,
    required this.trips,
    required this.onTripSelected,
    this.selectedTrip,
  });

  final List<Trip> trips;
  final Trip? selectedTrip;
  final ValueChanged<Trip> onTripSelected;

  @override
  State<TripBottomSheet> createState() => _TripBottomSheetState();
}

class _TripBottomSheetState extends State<TripBottomSheet> {
  static const double _peekSize = 0.2;
  static const double _defaultSize = 0.4;
  static const double _expandedSize = 0.9;

  final DraggableScrollableController _controller =
      DraggableScrollableController();

  bool _isCollapsed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TripBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Une nouvelle recherche rouvre le panneau.
    if (oldWidget.trips != widget.trips) {
      _isCollapsed = false;
    }
  }

  void _animateTo(double size) {
    _controller.animateTo(
      size,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _toggleSize() {
    final bool isLarge = _controller.size >= (_defaultSize + _expandedSize) / 2;
    _animateTo(isLarge ? _defaultSize : _expandedSize);
  }

  void _onHandleDragEnd(DragEndDetails details) {
    final double velocity = details.primaryVelocity ?? 0;
    if (velocity > 150) {
      _animateTo(_peekSize);
    } else if (velocity < -150) {
      _animateTo(_expandedSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCollapsed) {
      return _buildCollapsedPill(context);
    }

    return DraggableScrollableSheet(
      controller: _controller,
      initialChildSize: _defaultSize,
      minChildSize: _peekSize,
      maxChildSize: _expandedSize,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool showTitle = constraints.maxHeight >= 110;

              return Column(
                children: [
                  _buildTopBar(),
                  if (showTitle) _buildTitle(),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: widget.trips.length,
                      itemBuilder: (BuildContext context, int index) {
                        final Trip trip = widget.trips[index];
                        return TripCard(
                          trip: trip,
                          isSelected: trip.tripId == widget.selectedTrip?.tripId,
                          onTap: () => widget.onTripSelected(trip),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return SizedBox(
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleSize,
            onVerticalDragEnd: _onHandleDragEnd,
            child: const SizedBox(
              width: double.infinity,
              height: 40,
              child: Center(
                child: SizedBox(
                  width: 40,
                  height: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Réduire pour voir la carte',
              icon: const Icon(Icons.expand_more),
              onPressed: () => setState(() => _isCollapsed = true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    final int count = widget.trips.length;
    final String plural = count > 1 ? 's' : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$count trajet$plural trouvé$plural',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }

  Widget _buildCollapsedPill(BuildContext context) {
    final int count = widget.trips.length;
    final String plural = count > 1 ? 's' : '';

    return Column(
      children: [
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(28),
            color: Theme.of(context).colorScheme.surface,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => setState(() => _isCollapsed = false),
              child: SizedBox(
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.route,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '$count trajet$plural trouvé$plural',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      const Text('Afficher'),
                      const SizedBox(width: 4),
                      const Icon(Icons.expand_less),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}