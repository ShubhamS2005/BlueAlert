import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHandlerScreen extends StatefulWidget {
  final Widget child;
  const PermissionHandlerScreen({super.key, required this.child});

  @override
  State<PermissionHandlerScreen> createState() => _PermissionHandlerScreenState();
}

class _PermissionHandlerScreenState extends State<PermissionHandlerScreen> {
  bool _allPermissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    // Request all permissions at once
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.systemAlertWindow, // For full-screen alerts
    ].request();

    // Check if all requested permissions were granted
    if (statuses.values.every((status) => status.isGranted)) {
      if(mounted) {
        setState(() {
          _allPermissionsGranted = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_allPermissionsGranted) {
      return widget.child;
    }

    // If permissions are not granted, show this UI
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 20),
              const Text(
                'Permissions Required',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'BlueAlert needs access to your location, camera, and microphone for reporting hazards and providing safety alerts. Please grant these permissions to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  // If user denies, they can be taken to app settings
                  await openAppSettings();
                },
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)
                ),
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}