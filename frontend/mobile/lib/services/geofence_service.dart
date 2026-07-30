import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'push_notification_service.dart';

class GeofenceService {
  // Campus center coordinates (Sri Shakthi / Hostel Campus)
  static const double campusLatitude = 11.0168;
  static const double campusLongitude = 76.9558;
  static const double geofenceRadiusMeters = 400.0;

  static StreamSubscription<Position>? _positionSubscription;
  static bool _insideCampus = false;

  /// Start monitoring student position for geofenced campus return
  static Future<void> startCampusGeofenceMonitoring() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 30,
      ),
    ).listen((Position position) {
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        campusLatitude,
        campusLongitude,
      );

      debugPrint('[Geofence] Distance to campus: ${distance.toStringAsFixed(1)} meters');

      if (distance <= geofenceRadiusMeters && !_insideCampus) {
        _insideCampus = true;
        PushNotificationService().showSystemNotification(
          title: 'Campus Re-entry Detected 📍',
          body: 'You have entered the hostel campus. Tap to complete your return scan.',
          data: {'event': 'GEOFENCE_RETURN_DETECTED'},
        );
      } else if (distance > geofenceRadiusMeters) {
        _insideCampus = false;
      }
    });
  }

  static void stopMonitoring() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
