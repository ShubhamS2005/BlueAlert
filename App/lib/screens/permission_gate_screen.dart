import 'package:bluealert/screens/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// An enum to manage the different states of the screen
enum PermissionState { checking, granted, denied }

class PermissionGateScreen extends StatefulWidget {
  const PermissionGateScreen({super.key});

  @override
  State<PermissionGateScreen> createState() => _PermissionGateScreenState();
}

class _PermissionGateScreenState extends State<PermissionGateScreen> {
  PermissionState _state = PermissionState.checking;

  @override
  void initState() {
    super.initState();
    _checkInitialPermissions();
  }

  /// Checks permissions status without asking. Navigates away if already granted.
  Future<void> _checkInitialPermissions() async {
    // Check the status of all critical permissions.
    final locationStatus = await Permission.location.status;
    final cameraStatus = await Permission.camera.status;
    final notificationStatus = await Permission.notification.status;
    final alertWindowStatus = await Permission.systemAlertWindow.status;

    if (locationStatus.isGranted &&
        cameraStatus.isGranted &&
        notificationStatus.isGranted &&
        alertWindowStatus.isGranted) {
      // If everything is already granted, navigate immediately to the app.
      _navigateToApp();
    } else {
      // If not, update the state to show the permission request UI.
      if (mounted) {
        setState(() {
          _state = PermissionState.denied;
        });
      }
    }
  }

  /// Navigates to the main app logic (AuthWrapper).
  void _navigateToApp() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    }
  }

  /// Asks the user for permissions when the button is pressed.
  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.notification,
      Permission.systemAlertWindow,
    ].request();

    // After the request, check again.
    final areGranted = await _areAllPermissionsGranted();
    if (areGranted) {
      _navigateToApp();
    } else {
      // Only show the "Open Settings" popup if the user has permanently denied a permission.
      _showPermissionDeniedDialog();
    }
  }

  /// A helper to re-check all permissions after a request.
  Future<bool> _areAllPermissionsGranted() async {
    final statuses = await [
      Permission.location,
      Permission.camera,
      Permission.notification,
      Permission.systemAlertWindow,
    ].map((p) => p.status).toList();

    final results = await Future.wait(statuses);
    return results.every((status) => status.isGranted);
  }

  void _showPermissionDeniedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Permissions Required"),
        content: const Text(
            "BlueAlert requires critical permissions to function. Please manually grant them from your device settings to continue."),
        actions: <Widget>[
          TextButton(
            child: const Text("Open Settings"),
            onPressed: () {
              openAppSettings();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading screen while checking permissions initially.
    if (_state == PermissionState.checking) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/foreground.png', width: 150),
              const SizedBox(height: 30),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    // If permissions were not granted, show the request UI.
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/foreground.png', width: 120),
              const SizedBox(height: 24),
              const Text(
                'Welcome to BlueAlert',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'To protect you with real-time hazard alerts, we need access to your location, camera, and notification services.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _requestPermissions,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: const Text('Grant Permissions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}