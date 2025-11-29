import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapaPage extends StatelessWidget {
  final double latitud;
  final double longitud;
  final String direccion;

  const MapaPage({
    super.key,
    required this.latitud,
    required this.longitud,
    required this.direccion,
  });

  @override
  Widget build(BuildContext context) {
    final punto = LatLng(latitud, longitud);

    return Scaffold(
      appBar: AppBar(title: const Text("Ubicación de entrega")),
      body: FlutterMap(
        options: MapOptions(initialCenter: punto, initialZoom: 16),
        children: [
          TileLayer(
            urlTemplate:
                "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
            subdomains: const ['a', 'b', 'c', 'd'],
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: punto,
                width: 50,
                height: 50,
                child: const Icon(
                  Icons.location_pin,
                  size: 50,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
