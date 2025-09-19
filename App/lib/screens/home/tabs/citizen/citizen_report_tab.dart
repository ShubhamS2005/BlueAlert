import 'dart:io';
import 'package:bluealert/providers/auth_provider.dart';
import 'package:bluealert/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class CitizenReportTab extends StatefulWidget {
  const CitizenReportTab({super.key});

  @override
  State<CitizenReportTab> createState() => _CitizenReportTabState();
}

class _CitizenReportTabState extends State<CitizenReportTab> {
  final _textController = TextEditingController();
  XFile? _mediaFile;
  bool _isSubmitting = false;

  Future<void> _captureMedia(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: source, imageQuality: 80);

    if (file != null) {
      setState(() {
        _mediaFile = file;
      });
    }
  }

  // --- FIX: Implemented actual report submission ---
  Future<void> _submitReport() async {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please describe the hazard.'), backgroundColor: Colors.orange,));
      return;
    }
    setState(() => _isSubmitting = true);

    final connectivityResult = await (Connectivity().checkConnectivity());
    bool isOnline = connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi);

    try {
      if (isOnline) {
        // --- ONLINE SUBMISSION LOGIC ---
        final token = Provider.of<AuthProvider>(context, listen: false).token;
        if (token == null) throw Exception("User not authenticated.");

        // Get current location to tag the report
        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

        await ApiService().submitReport(
          text: _textController.text,
          lat: position.latitude,
          lon: position.longitude,
          token: token,
          mediaFile: _mediaFile != null ? File(_mediaFile!.path) : null,
        );

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted successfully!'), backgroundColor: Colors.green,));

        // Clear the form after success
        _clearForm();

      } else {
        // --- OFFLINE QUEUING LOGIC ---
        final reportData = {
          'text': _textController.text,
          'timestamp': DateTime.now().toIso8601String(),
        };

        if (_mediaFile != null) {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = p.basename(_mediaFile!.path);
          final savedImage = await File(_mediaFile!.path).copy('${directory.path}/$fileName');
          reportData['mediaPath'] = savedImage.path;
        }

        final prefs = await SharedPreferences.getInstance();
        List<String> queuedReports = prefs.getStringList('offline_reports') ?? [];
        queuedReports.add(jsonEncode(reportData));
        await prefs.setStringList('offline_reports', queuedReports);

        Workmanager().registerOneOffTask("syncReportsTask", "syncReportsTask", constraints: Constraints(networkType: NetworkType.connected));

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offline. Report queued for sync.'), backgroundColor: Colors.orange,));

        _clearForm();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red,));
    } finally {
      if(mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _clearForm() {
    _textController.clear();
    setState(() {
      _mediaFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Create a New Report', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),
          TextField(
            controller: _textController,
            decoration: const InputDecoration(labelText: 'Describe the hazard...', border: OutlineInputBorder()),
            maxLines: 5,
          ),
          const SizedBox(height: 20),

          // --- FIX: Image Preview UI ---
          if (_mediaFile == null)
            OutlinedButton.icon(
              onPressed: () => _captureMedia(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Add a Photo'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            )
          else
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(
                    File(_mediaFile!.path),
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => setState(() => _mediaFile = null),
                  ),
                ),
              ],
            ),
          // --- END FIX ---

          const SizedBox(height: 30),
          _isSubmitting
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
            onPressed: _submitReport,
            child: const Text('Submit Report'),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          )
        ],
      ),
    );
  }
}