import 'dart:async';
import 'package:flutter/material.dart';
import '../providers/api_client.dart';
import 'push_notification_service.dart';

class LiveAlertService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  static Timer? _pollTimer;
  static final Set<String> _seenNotificationIds = {};
  static bool _isPolling = false;

  /// Start polling for real-time live alert notifications
  static void startPolling() {
    if (_isPolling) return;
    _isPolling = true;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => checkLiveAlerts());
  }

  /// Stop polling
  static void stopPolling() {
    _isPolling = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    _seenNotificationIds.clear();
  }

  /// Check backend for new notifications and display OS status bar mobile notifications
  static Future<void> checkLiveAlerts() async {
    try {
      final res = await ApiClient.request('GET', '/notifications/?is_read=false');
      if (res['success'] == true && res['data'] != null) {
        List list = [];
        if (res['data'] is List) {
          list = res['data'] as List;
        } else if (res['data'] is Map && res['data']['results'] is List) {
          list = res['data']['results'] as List;
        }

        for (final item in list) {
          final m = Map<String, dynamic>.from(item);
          final id = m['id']?.toString() ?? '';
          if (id.isNotEmpty && !_seenNotificationIds.contains(id)) {
            _seenNotificationIds.add(id);
            
            // Trigger OS System Mobile Notification (Status bar / Notification Shade)
            PushNotificationService().showSystemNotification(
              title: m['title'] ?? 'System Alert',
              body: m['message'] ?? '',
              data: m,
            );
          }
        }
      }
    } catch (_) {}
  }
}
