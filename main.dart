import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leaf Specialist',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const LeafDiagnosisPage(),
    );
  }
}

class LeafDiagnosisPage extends StatefulWidget {
  const LeafDiagnosisPage({super.key});

  @override
  State<LeafDiagnosisPage> createState() => _LeafDiagnosisPageState();
}

class _LeafDiagnosisPageState extends State<LeafDiagnosisPage> {
  File? _image;
  bool _isLoading = false;
  String? _species;
  String? _disease;
  String? _latitude;
  String? _longitude;
  final ImagePicker _picker = ImagePicker();

  // ← CHANGE THIS TO YOUR LAPTOP'S IP
  final String serverUrl = 'http://10.231.249.8:8000/predict';

  // Get current location
  Future<Position?> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _pickAndAnalyze() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    if (picked == null) return;

    setState(() {
      _image = File(picked.path);
      _isLoading = true;
      _species = null;
      _disease = null;
      _latitude = null;
      _longitude = null;
    });

    // Get location
    Position? position = await _getLocation();
    if (position != null) {
      _latitude = position.latitude.toString();
      _longitude = position.longitude.toString();
    }

    try {
      var request = http.MultipartRequest('POST', Uri.parse(serverUrl));
      
      // Add image
      request.files.add(
        await http.MultipartFile.fromPath('file', picked.path)
      );

      // Add location if available
      if (_latitude != null && _longitude != null) {
        request.fields['latitude'] = _latitude!;
        request.fields['longitude'] = _longitude!;
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      var result = jsonDecode(responseBody);

      setState(() {
        _species = result['species'];
        _disease = result['disease'];
        _isLoading = false;
      });

    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Error'),
            content: Text('Could not connect to server: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              )
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Leaf Specialist',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),

            // Image preview
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  )
                ],
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.eco, size: 80, color: Colors.green),
                        SizedBox(height: 10),
                        Text('No image selected',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Analyze button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAndAnalyze,
              icon: const Icon(Icons.search),
              label: Text(_isLoading ? 'Analyzing...' : 'Analyze Leaf'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Loading indicator
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.green)
              ),

            // Results
            if (_species != null && _disease != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Diagnosis Result',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.local_florist, color: Colors.green),
                        const SizedBox(width: 8),
                        const Text('Plant: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(_species!)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.bug_report, color: Colors.red),
                        const SizedBox(width: 8),
                        const Text('Status: ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(_disease!)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Show location if available
                    if (_latitude != null && _longitude != null) ...[
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text('Location: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              '${double.parse(_latitude!).toStringAsFixed(4)}°N, '
                              '${double.parse(_longitude!).toStringAsFixed(4)}°E',
                            ),
                          ),
                        ],
                      ),

          const SizedBox(height: 16), 
          ElevatedButton.icon(
            onPressed: () async {
              final url = 'https://www.google.com/maps/search/pesticide+agricultural+shop/@${_latitude},${_longitude},13z';
              final uri = Uri.parse(url);
              
              try {
                await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication
                );
              } catch (e) {
                debugPrint('Could not launch Maps: $e');
              }
            },
            icon: const Icon(Icons.store),
            label: const Text('Find Nearby Pesticide Shops'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

                    ] else ...[
                      const Row(
                        children: [
                          Icon(Icons.location_off, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('Location not available',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    ]
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}