import 'dart:async';
import 'package:bluealert/providers/auth_provider.dart';
import 'package:bluealert/screens/home/full_screen_image_viewer.dart';
import 'package:bluealert/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

class ReportDetailScreen extends StatefulWidget {
  final Map<String, dynamic> report;
  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  StreamSubscription<Position>? _positionStream;
  double _distanceInMeters = 0;
  final MapController _mapController = MapController();
  latlng.LatLng? _userPosition;
  List<Marker> _markers = [];

  // --- FIX 1: The missing state variable has been declared ---
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _setInitialMarkers();
    _listenToUserLocation();
  }

  void _setInitialMarkers() {
    final reportLocation = latlng.LatLng(
      widget.report['location']['coordinates'][1],
      widget.report['location']['coordinates'][0],
    );
    _markers.add(
      Marker(
        point: reportLocation,
        width: 80,
        height: 80,
        child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
      ),
    );
  }

  void _listenToUserLocation() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      if (!mounted) return;

      final newUserPos = latlng.LatLng(position.latitude, position.longitude);
      final reportLocation = latlng.LatLng(
        widget.report['location']['coordinates'][1],
        widget.report['location']['coordinates'][0],
      );

      setState(() {
        _userPosition = newUserPos;
        _distanceInMeters = Geolocator.distanceBetween(
          newUserPos.latitude, newUserPos.longitude,
          reportLocation.latitude, reportLocation.longitude,
        );
      });
    });
  }

  // --- FIX 2: The logic for the verify function has been fully implemented ---
  Future<void> _verifyReport() async {
    setState(() => _isVerifying = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      await ApiService().verifyReport(reportId: widget.report['_id'], token: token!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report successfully verified!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true); // Pop and return true to refresh the list
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if(mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userRole = Provider.of<AuthProvider>(context, listen: false).user?.role;
    final reportLocation = latlng.LatLng(
      widget.report['location']['coordinates'][1],
      widget.report['location']['coordinates'][0],
    );

    // Build the list of markers dynamically for flutter_map
    List<Marker> currentMarkers = List.from(_markers);
    if (_userPosition != null) {
      currentMarkers.add(
        Marker(
          point: _userPosition!,
          width: 80,
          height: 80,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 30),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Report Details')),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: reportLocation,
                initialZoom: 14.0,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.bluealert',
                ),
                MarkerLayer(markers: currentMarkers),
              ],
            ),
          ),
          Expanded(
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
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => FullScreenImageViewer(imageUrl: widget.report['media']['url']),
                          ));
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            widget.report['media']['url'],
                            width: double.infinity,
                            height: 250,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),

                  if (userRole == 'Analyst' && widget.report['status'] == 'Needs Verification')
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