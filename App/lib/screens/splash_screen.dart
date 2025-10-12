import 'package:bluealert/screens/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // A state variable to control the UI
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _handlePermissions();
  }

  /// The main logic hub for permissions.
  Future<void> _handlePermissions() async {
    // First, just check the status without requesting.
    if (await _areAllPermissionsGranted()) {
      // If we already have them, go straight to the app.
      _navigateToApp();
    } else {
      // If not, stop the loading spinner and show the permission request button.
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  /// Navigates to the main app logic (the AuthWrapper).
  void _navigateToApp() {
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
      );
    }
  }

  /// This function is called ONLY when the user presses the "Grant Permissions" button.
  Future<void> _requestPermissions() async {
    // Request all permissions. This shows the system's permission dialogs.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      Permission.notification,
      Permission.systemAlertWindow,
    ].request();

    // After the user has responded, check the status again.
    if (await _areAllPermissionsGranted()) {
      _navigateToApp();
    } else {
      // --- FIX: Check if any permission was PERMANENTLY denied ---
      // This happens if the user selects "Deny & Don't ask again".
      if (statuses.values.any((status) => status.isPermanentlyDenied)) {
        _showOpenSettingsDialog();
      } else {
        // If they just denied it once, show a temporary message. They can tap the button again.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All permissions are required to use the app.')),
          );
        }
      }
    }
  }

  /// A helper to re-check all critical permissions.
  Future<bool> _areAllPermissionsGranted() async {
    final statuses = await Future.wait([
      Permission.location.status,
      Permission.camera.status,
      Permission.notification.status,
      Permission.systemAlertWindow.status,
    ]);
    return statuses.every((status) => status.isGranted);
  }

  /// Shows a dialog that guides the user to their phone's settings.
  void _showOpenSettingsDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text("Permissions Required"),
        content: const Text(
            "Some permissions were permanently denied. Please go to your device settings to enable them for BlueAlert."),
        actions: <Widget>[
          TextButton(
            child: const Text("Open Settings"),
            onPressed: () {
              openAppSettings(); // Takes user to the app's settings page
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading UI while checking permissions initially.
    if (_isChecking) {
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