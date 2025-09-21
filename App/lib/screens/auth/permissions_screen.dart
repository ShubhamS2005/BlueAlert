import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bluealert/screens/auth/auth_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // A map of permissions we need to ask for.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
      Permission.microphone,
      // Add other permissions like storage, notification, etc., as needed.
      // Permission.ignoreBatteryOptimizations, // For background work
      // Permission.systemAlertWindow, // For draw-over-screen alerts
    ].request();

    // After permissions are requested (granted or denied), mark this screen as completed.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_requested', true);

    // Navigate to the main app flow.
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // This screen will likely only be visible for a moment.
    // You can build a more elaborate UI here explaining why permissions are needed.
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Requesting necessary permissions..."),
          ],
        ),
      ),
    );
  }
}