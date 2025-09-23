import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

class AlertScreen extends StatefulWidget {
  final String lat;
  final String lon;

  const AlertScreen({super.key, required this.lat, required this.lon});

  @override
  State<AlertScreen> createState() => _AlertScreenState();
}

class _AlertScreenState extends State<AlertScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Faster blink
    )..repeat(reverse: true);
    _playAlertSound();
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        _stopAlertSound();
        Navigator.of(context).pop();
      }
    });
  }

  Future<void> _playAlertSound() async {
    await _audioPlayer.setVolume(1.0);
    await _audioPlayer.play(AssetSource('sounds/alert_sound.mp3'));
  }

  Future<void> _stopAlertSound() async {
    await _audioPlayer.stop();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _openMap() async {
    await _stopAlertSound();
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=${widget.lat},${widget.lon}');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- FIX: Blinking '!' inside a red triangle ---
            SizedBox(
              width: 150,
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // The outer triangle
                  const Icon(
                    Icons.warning_rounded,
                    color: Colors.red,
                    size: 150,
                  ),
                  // The blinking exclamation mark
                  FadeTransition(
                    opacity: _animationController,
                    child: const Text(
                      "!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "HAZARD ALERT",
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "A critical hazard has been verified. Proceed with caution.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 18),
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton.icon(
              onPressed: _openMap,
              icon: const Icon(Icons.map_outlined, color: Colors.black),
              label: const Text("VIEW ON MAP", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellowAccent,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}