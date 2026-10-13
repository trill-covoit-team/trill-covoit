import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'widgets/route_map_widget.dart';

void main() {
  runApp(const TrillCovoitApp());
}

class TrillCovoitApp extends StatelessWidget {
  const TrillCovoitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TRILL Covoit\'',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MapPage(),
    );
  }
}

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    const startPoint = LatLng(43.614475, 1.331322);
    const endPoint = LatLng(43.569648, 1.465114);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte et itinéraire'),
      ),
      body: const RouteMapWidget(
        startPoint: startPoint,
        endPoint: endPoint, // Passer `null` pour afficher uniquement la carte
      ),
    );
  }
}