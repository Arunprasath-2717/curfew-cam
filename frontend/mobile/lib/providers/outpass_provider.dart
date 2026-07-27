import 'dart:convert';
import 'package:flutter/material.dart';
import 'api_client.dart';
import 'watchman_service.dart';

class OutpassQrToken {
  final String outpassId;
  final String token;
  final DateTime issuedAt;
  final DateTime expiresAt;

  OutpassQrToken({
    required this.outpassId,
    required this.token,
    required this.issuedAt,
    required this.expiresAt,
  });

  Map<String, dynamic> toQrPayload() => {
        'outpassId': outpassId,
        'token': token,
        'issuedAt': issuedAt.toIso8601String(),
      };
}

class GateLogEntry {
  final String id;
  final String studentName;
  final String scanType;
  final DateTime timestamp;

  GateLogEntry({
    required this.id,
    required this.studentName,
    required this.scanType,
    required this.timestamp,
  });

  factory GateLogEntry.fromJson(Map<String, dynamic> json) {
    return GateLogEntry(
      id: json['id']?.toString() ?? '',
      studentName: json['student_name'] ?? 'Student',
      scanType: json['scan_type'] ?? 'EXIT',
      timestamp: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

class OutpassProvider extends ChangeNotifier {
  List<GateLogEntry> _gateLogs = [];
  List<GateLogEntry> get gateLogs => List.unmodifiable(_gateLogs);

  Future<Map<String, dynamic>> getCurrentOutpass() =>
      ApiClient.request('GET', '/outpass/current/');

  Future<Map<String, dynamic>> getOutpassHistory() =>
      ApiClient.request('GET', '/outpass/history/');

  Future<Map<String, dynamic>> requestOutpass(Map<String, dynamic> data) =>
      ApiClient.request('POST', '/outpass/request/', body: data);

  Future<Map<String, dynamic>> verifyLocation(Map<String, dynamic> data) =>
      ApiClient.request('POST', '/students/verify-location/', body: data);

  Future<Map<String, dynamic>> markReturn(String outpassId, String method) =>
      ApiClient.request('POST', '/outpass/$outpassId/return/', body: {'auto_detect_method': method});

  Future<Map<String, dynamic>> getNotifications() =>
      ApiClient.request('GET', '/notifications/');

  Future<Map<String, dynamic>> markAllNotificationsRead() =>
      ApiClient.request('POST', '/notifications/mark-all-read/');

  Future<OutpassQrToken?> generateToken(String outpassId) async {
    final res = await ApiClient.request('POST', '/qr/regenerate/$outpassId/');
    if (res['success'] == true && res['data'] != null) {
      final data = res['data'] as Map<String, dynamic>;
      final token = OutpassQrToken(
        outpassId: outpassId,
        token: data['token'] ?? '',
        issuedAt: DateTime.now(),
        expiresAt: DateTime.tryParse(data['expires_at'] ?? '') ??
            DateTime.now().add(const Duration(hours: 1)),
      );
      notifyListeners();
      return token;
    }
    return null;
  }

  Future<Map<String, dynamic>> validateAndConsumeToken(String qrPayload, [String? scanType]) async {
    String token = qrPayload;
    try {
      final parsed = jsonDecode(qrPayload);
      if (parsed is Map && parsed['token'] != null) {
        token = parsed['token'] as String;
      }
    } catch (_) {}

    final res = await WatchmanService.scanQr(token, scanType);
    if (res['success'] == true) {
      await refreshGateLogs();
      final data = res['data'] as Map<String, dynamic>? ?? {};
      final actualScanType = data['scan_type']?.toString() ?? scanType ?? 'EXIT';
      return {
        'status': actualScanType == 'EXIT' ? 'EXIT_SUCCESS' : 'RETURN_SUCCESS',
        'outpassId': data['outpass']?.toString() ?? '',
        'studentName': data['student_name'] ?? 'Student',
      };
    }

    final msg = (res['message'] ?? '').toString().toLowerCase();
    if (msg.contains('expired')) return {'status': 'INVALID', 'message': 'This QR code has expired.'};
    if (msg.contains('used')) return {'status': 'INVALID', 'message': 'This QR code has already been used.'};
    return {'status': 'NOT_FOUND', 'message': res['message'] ?? 'Invalid QR'};
  }

  Future<void> refreshGateLogs() async {
    final res = await WatchmanService.getScanLogs();
    if (res['success'] == true && res['data'] is List) {
      _gateLogs = (res['data'] as List)
          .map((e) => GateLogEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      notifyListeners();
    }
  }
}
