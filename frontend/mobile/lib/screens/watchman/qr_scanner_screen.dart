import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/outpass_provider.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  MobileScannerController? _scannerController;
  bool _hasPermission = false;
  bool _permissionDenied = false;
  bool _isProcessing = false;
  String? _lastScannedPayload;
  DateTime? _lastScanTime;
  bool _torchOn = false;
  String? _lastConsumedPayload; // For demo: stores the payload that was just consumed

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _hasPermission = status.isGranted;
        _permissionDenied = status.isPermanentlyDenied || status.isDenied;
      });
      if (_hasPermission) {
        _scannerController = MobileScannerController(
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
          torchEnabled: false,
        );
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    // Debounce: ignore the same payload within 2 seconds
    final now = DateTime.now();
    if (_lastScannedPayload == rawValue &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!).inSeconds < 2) {
      return;
    }

    _lastScannedPayload = rawValue;
    _lastScanTime = now;

    _processScannedCode(rawValue);
  }

  Future<void> _processScannedCode(String payload) async {
    setState(() => _isProcessing = true);

    final provider = Provider.of<OutpassProvider>(context, listen: false);

    // Auto-detect exit/return directly from outpass state
    final result = await provider.validateAndConsumeToken(payload);

    if (!mounted) return;

    setState(() => _isProcessing = false);

    final status = result['status'] as String;

    if (kDebugMode) {
      debugPrint('[QR_SCAN] payload=$payload');
      debugPrint('[QR_SCAN] result=$result');
    }

    switch (status) {
      case 'EXIT_SUCCESS':
        setState(() => _lastConsumedPayload = payload);
        Navigator.pushReplacementNamed(context, '/scan-exit');
        break;
      case 'RETURN_SUCCESS':
        setState(() => _lastConsumedPayload = payload);
        Navigator.pushReplacementNamed(context, '/scan-return');
        break;
      case 'INVALID':
        Navigator.pushReplacementNamed(context, '/scan-invalid');
        break;
      case 'NOT_FOUND':
      default:
        Navigator.pushReplacementNamed(context, '/scan-not-found');
        break;
    }
  }

  /// Debug-only: simulate scanning the current active token for PASS-20CS101
  Future<void> _demoScanCurrentToken() async {
    final provider = Provider.of<OutpassProvider>(context, listen: false);
    // Generate a token first (as the student would), then immediately scan it
    final token = await provider.generateToken('00000000-0000-0000-0000-000000000000');
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo failed: token is null')),
        );
      }
      setState(() => _isProcessing = false);
      return;
    }
    final payload = jsonEncode(token.toQrPayload());
    if (kDebugMode) {
      debugPrint('[DEMO] Generated token: ${token.token}');
      debugPrint('[DEMO] Payload: $payload');
    }
    await _processScannedCode(payload);
  }

  /// Debug-only: re-scan the last consumed payload (should route to INVALID)
  Future<void> _demoRescanConsumedToken() async {
    if (_lastConsumedPayload == null) return;
    if (kDebugMode) {
      debugPrint('[DEMO] Re-scanning consumed payload: $_lastConsumedPayload');
    }
    await _processScannedCode(_lastConsumedPayload!);
  }

  void _toggleTorch() {
    if (_scannerController != null) {
      _scannerController!.toggleTorch();
      setState(() => _torchOn = !_torchOn);
    }
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 4,
        title: Row(children: [Icon(Icons.security, size: 20), const SizedBox(width: 8), Text('GateControl', style: TextStyle(fontWeight: FontWeight.bold))]),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Spacer(),
            // Viewfinder with real camera or permission message
            SizedBox(
              width: 280,
              height: 280,
              child: _buildScannerArea(context),
            ),
            const SizedBox(height: 32),
            if (_isProcessing)
              Column(
                children: [
                  CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(height: 8),
                  Text('Validating...', style: AppTextStyles.sectionHeader.copyWith(color: Theme.of(context).scaffoldBackgroundColor)),
                ],
              )
            else
              Text("Scan student's outpass QR", style: AppTextStyles.sectionHeader.copyWith(color: Theme.of(context).scaffoldBackgroundColor), textAlign: TextAlign.center),
            // --- DEBUG-ONLY DEMO BUTTONS (never shown in release builds) ---
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _demoScanCurrentToken,
                      icon: Icon(Icons.bug_report, size: 18),
                      label: Text('DEMO: Simulate Scan'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: (_isProcessing || _lastConsumedPayload == null) ? null : _demoRescanConsumedToken,
                      icon: Icon(Icons.replay, size: 18),
                      label: Text('DEMO: Re-scan OLD Token'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            // Footer Actions
            TextButton(onPressed: () => Navigator.pushNamed(context, '/manual-verification'), child: Text('Manual Entry', style: AppTextStyles.bodySecondary.copyWith(color: Colors.white.withValues(alpha: 0.8), decoration: TextDecoration.underline))),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _hasPermission ? _toggleTorch : null,
                  child: Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: _torchOn ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1), border: Border.all(color: _torchOn ? Theme.of(context).colorScheme.secondary : Colors.white.withValues(alpha: 0.2))), child: Icon(_torchOn ? Icons.flashlight_off : Icons.flashlight_on, color: _torchOn ? Theme.of(context).colorScheme.secondary : Theme.of(context).scaffoldBackgroundColor)),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/gate-log'),
                  child: Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1), border: Border.all(color: Colors.white.withValues(alpha: 0.2))), child: Icon(Icons.history, color: Theme.of(context).scaffoldBackgroundColor)),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerArea(BuildContext context) {
    if (_permissionDenied) {
      return _buildPermissionDeniedView(context);
    }

    if (!_hasPermission) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).scaffoldBackgroundColor));
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // Real camera feed
          MobileScanner(
            controller: _scannerController!,
            onDetect: _onDetect,
          ),
          // Corner accent overlays (preserve wireframe styling)
          Positioned(top: 0, left: 0, child: Container(width: 40, height: 40, decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).scaffoldBackgroundColor, width: 4), left: BorderSide(color: Theme.of(context).scaffoldBackgroundColor, width: 4)), borderRadius: BorderRadius.only(topLeft: Radius.circular(12))))),
          Positioned(top: 0, right: 0, child: Container(width: 40, height: 40, decoration: BoxDecoration(border: Border(top: BorderSide(color: Theme.of(context).scaffoldBackgroundColor, width: 4), right: BorderSide(color: Theme.of(context).scaffoldBackgroundColor, width: 4)), borderRadius: BorderRadius.only(topRight: Radius.circular(12))))),
          Positioned(bottom: 0, left: 0, child: Container(width: 40, height: 40, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).scaffoldBackgroundColor, width: 4), left: BorderSide(color: Theme.of(context).scaffoldBackgroundColor, width: 4)), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(12))))),
          Positioned(bottom: 0, right: 0, child: Container(width: 40, height: 40, decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Theme.of(context).scaffoldBackgroundColor, width: 4), right: BorderSide(color: Theme.of(context).scaffoldBackgroundColor, width: 4)), borderRadius: BorderRadius.only(bottomRight: Radius.circular(12))))),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedView(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.3), width: 2),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.no_photography, size: 48, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(height: 12),
              Text('Camera Access Required', style: AppTextStyles.cardTitle.copyWith(color: Theme.of(context).scaffoldBackgroundColor), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Please enable camera permission in your device settings to scan QR codes.', style: AppTextStyles.bodySecondary.copyWith(color: Colors.white.withValues(alpha: 0.7)), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => openAppSettings(),
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary, foregroundColor: Theme.of(context).primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text('Open Settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
