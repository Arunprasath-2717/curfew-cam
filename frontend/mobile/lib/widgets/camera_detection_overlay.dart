import 'package:flutter/material.dart';
import '../services/person_detection_service.dart';

class CameraDetectionOverlay extends StatelessWidget {
  final List<DetectionResult> results;
  final Size previewSize;
  final Size screenSize;

  const CameraDetectionOverlay({
    super.key,
    required this.results,
    required this.previewSize,
    required this.screenSize,
  });

  @override
  Widget build(BuildContext context) {
    if (previewSize.isEmpty) return const SizedBox.shrink();

    return CustomPaint(
      size: screenSize,
      painter: _DetectionPainter(results, previewSize, screenSize),
    );
  }
}

class _DetectionPainter extends CustomPainter {
  final List<DetectionResult> results;
  final Size previewSize;
  final Size screenSize;

  _DetectionPainter(this.results, this.previewSize, this.screenSize);

  @override
  void paint(Canvas canvas, Size size) {
    if (results.isEmpty) return;

    final Paint boxPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final TextPainter textPainter = TextPainter(
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    for (var res in results) {
      final rect = res.boundingBox;
      // Convert normalized coordinates [0,1] to screen dimensions directly
      final double left = rect.left * screenSize.width;
      final double top = rect.top * screenSize.height;
      final double right = rect.right * screenSize.width;
      final double bottom = rect.bottom * screenSize.height;

      final mappedRect = Rect.fromLTRB(left, top, right, bottom);
      canvas.drawRect(mappedRect, boxPaint);

      textPainter.text = TextSpan(
        text: 'Person ${(res.confidence * 100).toStringAsFixed(1)}%',
        style: const TextStyle(
          color: Colors.white,
          backgroundColor: Colors.green,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(mappedRect.left, mappedRect.top - 20));
    }
  }

  @override
  bool shouldRepaint(covariant _DetectionPainter oldDelegate) {
    return true; // Always repaint as detections stream in
  }
}
