import 'dart:isolate';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class DetectionResult {
  final Rect boundingBox;
  final double confidence;

  DetectionResult(this.boundingBox, this.confidence);
}

class PersonDetectionService {
  Interpreter? _interpreter;
  bool _isProcessing = false;

  Future<void> initModel() async {
    final assetPath = 'assets/models/ssd_mobilenet.tflite';
    
    // Attempt 1: GPU Delegate
    try {
      final gpuOptions = InterpreterOptions()..addDelegate(GpuDelegateV2());
      _interpreter = await Interpreter.fromAsset(assetPath, options: gpuOptions);
      debugPrint("SUCCESS: Loaded TFLite model with GPU Delegate");
      return;
    } catch (e, stackTrace) {
      debugPrint("==================================================");
      debugPrint("GPU Delegate Initialization Failed");
      debugPrint("Exception: $e");
      debugPrint("StackTrace: $stackTrace");
      debugPrint("==================================================");
      debugPrint("Falling back to CPU...");
    }

    // Attempt 2: Default CPU Delegate
    try {
      _interpreter = await Interpreter.fromAsset(assetPath);
      debugPrint("Loaded TFLite model with CPU Delegate");
      return;
    } catch (e) {
      debugPrint("CPU Delegate failed with full path ($e). Trying alternate path...");
    }
    
    // Attempt 3: Alternate path (some tflite_flutter versions drop the assets/ prefix)
    try {
      _interpreter = await Interpreter.fromAsset('models/ssd_mobilenet.tflite');
      debugPrint("Loaded TFLite model with alternate path");
    } catch (e) {
      debugPrint("Failed to load TFLite model entirely: $e");
    }
  }

  void close() {
    _interpreter?.close();
  }

  Future<List<DetectionResult>> processCameraImage(CameraImage image) async {
    if (_interpreter == null || _isProcessing) return [];
    _isProcessing = true;

    try {
      final inputImage = await _convertCameraImage(image);
      if (inputImage == null) return [];

      final input = _imageToByteListUint8(inputImage, 300, 300);

      // SSD MobileNet output tensors
      final outputLocations = List.generate(1, (_) => List.generate(10, (_) => List.filled(4, 0.0)));
      final outputClasses = List.generate(1, (_) => List.filled(10, 0.0));
      final outputScores = List.generate(1, (_) => List.filled(10, 0.0));
      final numDetections = List.filled(1, 0.0);

      Map<int, Object> outputs = {
        0: outputLocations,
        1: outputClasses,
        2: outputScores,
        3: numDetections,
      };

      _interpreter!.runForMultipleInputs([input], outputs);

      final List<DetectionResult> results = [];
      final locations = outputLocations[0];
      final classes = outputClasses[0];
      final scores = outputScores[0];
      final count = numDetections[0].toInt();

      for (int i = 0; i < count; i++) {
        // Class 0 in COCO for SSD is person
        if (classes[i] == 0 && scores[i] > 0.5) {
          // locations are [ymin, xmin, ymax, xmax]
          final rect = Rect.fromLTRB(
            locations[i][1], // xmin
            locations[i][0], // ymin
            locations[i][3], // xmax
            locations[i][2], // ymax
          );
          results.add(DetectionResult(rect, scores[i]));
        }
      }

      return results;
    } catch (e) {
      debugPrint("Inference error: $e");
      return [];
    } finally {
      _isProcessing = false;
    }
  }

  Future<List<DetectionResult>> processNetworkImage(Uint8List jpegBytes) async {
    if (_interpreter == null || _isProcessing) return [];
    _isProcessing = true;

    try {
      final inputImage = await Isolate.run(() {
        return img.decodeImage(jpegBytes);
      });
      
      if (inputImage == null) return [];

      final input = _imageToByteListUint8(inputImage, 300, 300);

      final outputLocations = List.generate(1, (_) => List.generate(10, (_) => List.filled(4, 0.0)));
      final outputClasses = List.generate(1, (_) => List.filled(10, 0.0));
      final outputScores = List.generate(1, (_) => List.filled(10, 0.0));
      final numDetections = List.filled(1, 0.0);

      Map<int, Object> outputs = {
        0: outputLocations,
        1: outputClasses,
        2: outputScores,
        3: numDetections,
      };

      _interpreter!.runForMultipleInputs([input], outputs);

      final List<DetectionResult> results = [];
      final locations = outputLocations[0];
      final classes = outputClasses[0];
      final scores = outputScores[0];
      final count = numDetections[0].toInt();

      for (int i = 0; i < count; i++) {
        if (classes[i] == 0 && scores[i] > 0.5) {
          final rect = Rect.fromLTRB(
            locations[i][1], 
            locations[i][0], 
            locations[i][3], 
            locations[i][2], 
          );
          results.add(DetectionResult(rect, scores[i]));
        }
      }

      return results;
    } catch (e) {
      debugPrint("Network inference error: $e");
      return [];
    } finally {
      _isProcessing = false;
    }
  }

  Future<img.Image?> _convertCameraImage(CameraImage image) async {
    if (image.format.group == ImageFormatGroup.yuv420) {
      final int width = image.width;
      final int height = image.height;
      final List<Uint8List> planeBytes = image.planes.map((p) => p.bytes).toList();
      final List<int> bytesPerRow = image.planes.map((p) => p.bytesPerRow).toList();
      final List<int?> bytesPerPixel = image.planes.map((p) => p.bytesPerPixel).toList();

      return await Isolate.run(() {
        return _convertYUV420(width, height, planeBytes, bytesPerRow, bytesPerPixel);
      });
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      final width = image.width;
      final height = image.height;
      final bytes = image.planes[0].bytes;
      return await Isolate.run(() {
        return img.Image.fromBytes(
          width: width,
          height: height,
          bytes: bytes.buffer,
          order: img.ChannelOrder.bgra,
        );
      });
    }
    return null;
  }

  static img.Image _convertYUV420(int width, int height, List<Uint8List> planes, List<int> bytesPerRow, List<int?> bytesPerPixel) {
    final uvRowStride = bytesPerRow[1];
    final uvPixelStride = bytesPerPixel[1] ?? 1;

    final imgRes = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final uvIndex = uvPixelStride * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final index = y * width + x;

        final yp = planes[0][index];
        final up = planes[1][uvIndex];
        final vp = planes[2][uvIndex];

        int r = (yp + vp * 1436 / 1024 - 179).round();
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round();
        int b = (yp + up * 1814 / 1024 - 227).round();

        imgRes.setPixelRgb(x, y, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
      }
    }
    return imgRes;
  }

  Uint8List _imageToByteListUint8(img.Image image, int inputSize, int numChannels) {
    var resizedImage = img.copyResize(image, width: inputSize, height: inputSize);
    var convertedBytes = Uint8List(1 * inputSize * inputSize * numChannels);
    var buffer = ByteData.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = resizedImage.getPixel(j, i);
        buffer.setUint8(pixelIndex++, pixel.r.toInt());
        buffer.setUint8(pixelIndex++, pixel.g.toInt());
        buffer.setUint8(pixelIndex++, pixel.b.toInt());
      }
    }
    return convertedBytes;
  }
}
