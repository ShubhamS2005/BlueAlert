import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class CitizenMapTab extends StatefulWidget {
  const CitizenMapTab({super.key});

  @override
  State<CitizenMapTab> createState() => _CitizenMapTabState();
}

class _CitizenMapTabState extends State<CitizenMapTab> {
  GoogleMapController? mapController;
  LatLng _center = const LatLng(20.5937, 78.9629); // Default to India
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    // ... (Standard geolocator permission handling logic)
    // For brevity, assuming permissions are granted.
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        _isLoading = false;
        mapController?.animateCamera(CameraUpdate.newLatLngZoom(_center, 14));
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : GoogleMap(
      onMapCreated: (controller) => mapController = controller,
      initialCameraPosition: CameraPosition(target: _center, zoom: 11.0),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }
}