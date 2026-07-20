import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../services/person_detection_service.dart';
import '../../widgets/camera_detection_overlay.dart';
import '../../providers/warden_service.dart';

class GateMonitorScreen extends StatefulWidget {
  const GateMonitorScreen({super.key});

  @override
  State<GateMonitorScreen> createState() => _GateMonitorScreenState();
}

class _GateMonitorScreenState extends State<GateMonitorScreen> {
  CameraController? _cameraController;
  final PersonDetectionService _detectionService = PersonDetectionService();
  List<DetectionResult> _results = [];
  bool _isNightMode = false;
  int _frameCount = 0;
  bool _isProcessing = false;
  double _maxExposure = 0.0;

  String? _streamUrl;
  bool _isNetworkStream = false;
  Uint8List? _currentFrame;
  http.Client? _httpClient;

  @override
  void initState() {
    super.initState();
    _loadConfigAndInit();
    // Start backend YOLO stream only during curfew
    if (_isCurfewTime()) {
      WardenService.startDetectionStream().catchError((e) => debugPrint(e.toString()));
    }
  }

  bool _isCurfewTime() {
    final now = DateTime.now();
    final time = TimeOfDay.fromDateTime(now);
    if (time.hour > 20 || (time.hour == 20 && time.minute >= 15)) {
      return true; // 8:15 PM to 11:59 PM
    }
    if (time.hour < 6) {
      return true; // 12:00 AM to 5:59 AM
    }
    return false;
  }

  Future<void> _loadConfigAndInit() async {
    final prefs = await SharedPreferences.getInstance();
    _streamUrl = prefs.getString('gate_camera_url');
    
    if (_streamUrl != null && _streamUrl!.isNotEmpty) {
      _isNetworkStream = true;
      await _initNetworkStream();
    } else {
      await _initCameraAndModel();
    }
  }

  Future<void> _initNetworkStream() async {
    await _detectionService.initModel();
    _httpClient = http.Client();
    
    try {
      final request = http.Request('GET', Uri.parse(_streamUrl!));
      final response = await _httpClient!.send(request);
      
      if (response.statusCode == 200) {
        List<int> buffer = [];
        
        response.stream.listen((data) async {
          buffer.addAll(data);
          
          if (buffer.length > 1000000) { // cap at 1MB to prevent memory leak
            buffer.clear();
          }
          
          int start = -1;
          int end = -1;
          
          for (int i = 0; i < buffer.length - 1; i++) {
            if (buffer[i] == 0xFF && buffer[i+1] == 0xD8) start = i;
            if (buffer[i] == 0xFF && buffer[i+1] == 0xD9) end = i + 1;
          }
          
          if (start != -1 && end != -1 && end > start) {
            final frameData = Uint8List.fromList(buffer.sublist(start, end + 1));
            buffer = buffer.sublist(end + 1);
            
            if (mounted) {
              setState(() {
                _currentFrame = frameData;
              });
            }
            
            _frameCount++;
            if (_frameCount % 5 != 0) return;
            if (!_isCurfewTime()) return; // Skip YOLO processing outside curfew
            if (_isProcessing) return;
            
            _isProcessing = true;
            final results = await _detectionService.processNetworkImage(frameData);
            if (mounted) {
              setState(() {
                _results = results;
              });
            }
            _isProcessing = false;
          }
        }, onError: (e) {
          debugPrint("Stream error: $e");
        });
      }
    } catch (e) {
      debugPrint("Error connecting to stream: $e");
    }
  }

  Future<void> _initCameraAndModel() async {
    await _detectionService.initModel();

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _cameraController!.initialize();
    
    _maxExposure = await _cameraController!.getMaxExposureOffset();

    if (mounted) {
      setState(() {});
    }

    _cameraController!.startImageStream((image) async {
      _frameCount++;
      // Throttle: process every 5th frame
      if (_frameCount % 5 != 0) return;
      
      if (!_isCurfewTime()) return; // Skip YOLO processing outside curfew
      
      if (_isProcessing) return;
      _isProcessing = true;

      final results = await _detectionService.processCameraImage(image);
      
      if (mounted) {
        setState(() {
          _results = results;
        });
      }
      
      _isProcessing = false;
    });
  }

  Future<void> _toggleNightMode() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    setState(() {
      _isNightMode = !_isNightMode;
    });

    if (_isNightMode) {
      await _cameraController!.setExposureOffset(_maxExposure);
    } else {
      await _cameraController!.setExposureOffset(0.0); // Reset to default auto
    }
  }

  @override
  void dispose() {
    // Stop backend YOLO stream
    WardenService.stopDetectionStream().catchError((e) => debugPrint(e.toString()));
    
    _httpClient?.close();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _detectionService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isNetworkStream) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gate Monitor')),
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_currentFrame != null)
              Image.memory(_currentFrame!, fit: BoxFit.cover, gaplessPlayback: true)
            else
              const Center(child: CircularProgressIndicator(color: Colors.amber)),
            if (_currentFrame != null)
              CameraDetectionOverlay(
                results: _results,
                previewSize: const Size(1, 1),
                screenSize: MediaQuery.of(context).size,
              ),
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_results.length} Person(s) Detected (Network)',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gate Monitor')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final previewSize = _cameraController!.value.previewSize!;
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gate Monitor'),
        actions: [
          IconButton(
            icon: Icon(_isNightMode ? Icons.nightlight_round : Icons.wb_sunny),
            color: _isNightMode ? Colors.amber : Colors.white,
            onPressed: _toggleNightMode,
            tooltip: 'Toggle Night Mode',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          CameraDetectionOverlay(
            results: _results,
            previewSize: Size(previewSize.height, previewSize.width),
            screenSize: screenSize,
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_results.length} Person(s) Detected',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
