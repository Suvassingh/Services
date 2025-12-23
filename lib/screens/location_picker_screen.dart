import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:services/utils/app_constants.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key});

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  final MapController _mapController = MapController();

  LatLng selectedLatLng = LatLng(27.7172, 85.3240); // Kathmandu
  String address = "";
  double zoom = 13.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
          child: AppBar(
            title: const Text(
              "Pick Location",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppConstants.appTextColour,
              ),
            ),
            centerTitle: true,
            backgroundColor: AppConstants.appMainColour,
            elevation: 0,
            iconTheme: IconThemeData(color: AppConstants.appTextColour),
          ),
        ),
      ),      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: selectedLatLng,
              initialZoom: zoom,
              minZoom: 5,
              maxZoom: 18,

              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),

              onTap: (tapPos, latlng) async {
                setState(() => selectedLatLng = latlng);
                address = await reverseGeocode(
                  latlng.latitude,
                  latlng.longitude,
                );
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: selectedLatLng,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            right: 16,
            top: 100,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    zoom++;
                    _mapController.move(selectedLatLng, zoom);
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    zoom--;
                    _mapController.move(selectedLatLng, zoom);
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  "address": address,
                  "lat": selectedLatLng.latitude,
                  "lng": selectedLatLng.longitude,
                });
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text("Confirm Location"),
            ),
          ),
        ],
      ),
    );
  }

  Future<String> reverseGeocode(double lat, double lng) async {
    final url =
        "https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng";

    final res = await http.get(
      Uri.parse(url),
      headers: {"User-Agent": "FlutterLocationPicker"},
    );

    final data = jsonDecode(res.body);
    return data["display_name"] ?? "";
  }
}
