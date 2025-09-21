import 'dart:io';
import 'package:bluealert/providers/auth_provider.dart';
import 'package:bluealert/services/api_service.dart';
import 'package:bluealert/widgets/video_preview_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class CitizenCreateReportTab extends StatefulWidget {
  const CitizenCreateReportTab({super.key});

  @override
  State<CitizenCreateReportTab> createState() => _CitizenCreateReportTabState();
}

class _CitizenCreateReportTabState extends State<CitizenCreateReportTab> {
  final _textController = TextEditingController();
  XFile? _mediaFile;
  bool _isSubmitting = false;
  bool _isVideoflag = false;

  Future<void> _captureMedia(ImageSource source, {bool isVideo = false}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? file;
    if (isVideo) {
      file = await picker.pickVideo(source: source);
    } else {
      file = await picker.pickImage(source: source, imageQuality: 80);
    }

    if (file != null) {
      setState(() {
        _mediaFile = file;
        _isVideoflag = isVideo;
      });
    }
  }

  Future<void> _submitReport() async {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please describe the hazard.'), backgroundColor: Colors.orange,));
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      // --- FIX: Get AuthProvider and User ID ---
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.user?.id; // Get the user's ID

      if (token == null || userId == null) {
        throw Exception("Authentication error. Please log out and log in again.");
      }
      // --- END FIX ---

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      await ApiService().submitReport(
        text: _textController.text,
        lat: position.latitude,
        lon: position.longitude,
        token: token,
        userId: userId, // <-- FIX: Pass the user's ID to the service
        mediaFile: _mediaFile != null ? File(_mediaFile!.path) : null,
      );

      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted successfully!'), backgroundColor: Colors.green,));
      }
      _clearForm();

    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red,));
      }
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
      _isVideoflag = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // The build method remains exactly the same as before.
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

          if (_mediaFile != null)
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _isVideoflag
                      ? VideoPreviewWidget(videoFile: File(_mediaFile!.path))
                      : Image.file(File(_mediaFile!.path), width: double.infinity, height: 250, fit: BoxFit.cover),
                ),
                Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: _clearForm,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(onPressed: () => _captureMedia(ImageSource.camera), icon: const Icon(Icons.camera_alt_outlined), label: const Text('Photo')),
              ElevatedButton.icon(onPressed: () => _captureMedia(ImageSource.camera, isVideo: true), icon: const Icon(Icons.videocam_outlined), label: const Text('Video')),
            ],
          ),

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