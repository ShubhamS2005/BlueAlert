import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HotspotTab extends StatefulWidget {
  const HotspotTab({super.key});

  @override
  State<HotspotTab> createState() => _HotspotTabState();
}

class _HotspotTabState extends State<HotspotTab> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _loadError = false;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
    // JavaScript must be enabled for the map to work
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            // This will catch errors if the device is offline and cannot load external scripts
            if (mounted) {
              setState(() {
                _isLoading = false;
                _loadError = true;
              });
            }
          },
        ),
      )
    // Load the new hotspot map HTML file from local assets
      ..loadFlutterAsset('assets/web/hotspot_map.html');
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _controller),

        // Show a loading indicator while the page and its scripts are loading
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          ),

        // Show an error message if the page fails to load (e.g., no internet)
        if (_loadError)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load hotspots.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please check your internet connection and try again.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}