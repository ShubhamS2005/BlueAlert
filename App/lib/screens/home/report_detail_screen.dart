import 'dart:async';
import 'package:bluealert/providers/auth_provider.dart';
import 'package:bluealert/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class ReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> report;
  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  StreamSubscription<Position>? _positionStream;
  double _distanceInMeters = 0;
  final Set<Marker> _markers = {};
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _setInitialMarkers();
    _listenToUserLocation();
  }

  /// Sets the initial red pin for the hazard's location.
  void _setInitialMarkers() {
    final reportLocation = LatLng(
      widget.report['location']['coordinates'][1], // Lat is at index 1
      widget.report['location']['coordinates'][0], // Lon is at index 0
    );
    _markers.add(Marker(
      markerId: const MarkerId('reportLocation'),
      position: reportLocation,
      infoWindow: const InfoWindow(title: 'Hazard Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    ));
  }

  /// Subscribes to the phone's GPS to get real-time location updates.
  void _listenToUserLocation() async {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      if (!mounted) return;

      final newUserPos = LatLng(position.latitude, position.longitude);
      final reportLocation = LatLng(
        widget.report['location']['coordinates'][1],
        widget.report['location']['coordinates'][0],
      );

      setState(() {
        // Remove old user marker before adding the new one
        _markers.removeWhere((m) => m.markerId.value == 'userLocation');
        _markers.add(Marker(
          markerId: const MarkerId('userLocation'),
          position: newUserPos,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ));

        // Recalculate and update the distance
        _distanceInMeters = Geolocator.distanceBetween(
          newUserPos.latitude, newUserPos.longitude,
          reportLocation.latitude, reportLocation.longitude,
        );
      });
    });
  }

  /// Handles the API call for an analyst to verify a report.
  Future<void> _verifyReport() async {
    setState(() => _isVerifying = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      await ApiService().verifyReport(reportId: widget.report['_id'], token: token!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report successfully verified!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true); // Pop and return true to indicate success
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel(); // Important to prevent memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userRole = Provider.of<AuthProvider>(context, listen: false).user?.role;
    final reportLocation = LatLng(
      widget.report['location']['coordinates'][1],
      widget.report['location']['coordinates'][0],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Report Details')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(target: reportLocation, zoom: 14),
              markers: _markers,
              myLocationEnabled: false, // We use a custom marker for user location
              myLocationButtonEnabled: true,
            ),
          ),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.report['text'], style: Theme.of(context).textTheme.titleMedium),
                  const Divider(height: 20),
                  ListTile(
                    leading: const Icon(Icons.social_distance_outlined),
                    title: const Text('Distance from Hazard'),
                    subtitle: Text('${(_distanceInMeters / 1000).toStringAsFixed(2)} km'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Status'),
                    subtitle: Text(widget.report['status']),
                  ),
                  if (widget.report['media'] != null && widget.report['media']['url'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 16),
                      child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(widget.report['media']['url'])),
                    ),

                  // --- ANALYST-ONLY VERIFY BUTTON ---
                  if (userRole == 'Analyst' && widget.report['status'] != 'Verified')
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _isVerifying
                          ? const Center(child: CircularProgressIndicator())
                          : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Verify Report'),
                          onPressed: _verifyReport,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}