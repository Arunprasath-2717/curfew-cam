import 'dart:convert';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../providers/api_client.dart';

/// Top-level callback for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `Firebase.initializeApp()` before using other Firebase services.
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // 1. Request permissions for iOS and Android 13+
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 2. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        debugPrint('Notification tapped: ${response.payload}');
      },
    );

    // Create a high-importance channel for Android heads-up notifications
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.', // description
        importance: Importance.max,
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // iOS Foreground settings
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      _showLocalNotification(message);
    });

    // 4. Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _isInitialized = true;
  }

  void showSystemNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    if (title.isEmpty && body.isEmpty) return;

    final int notificationId = (title.hashCode + DateTime.now().millisecondsSinceEpoch).abs() % 100000;
    _localNotificationsPlugin.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important system alerts and notifications.',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          showWhen: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: data != null ? jsonEncode(data) : null,
    );
  }

  void _showLocalNotification(RemoteMessage message) {
    final title = message.notification?.title ?? message.data['title'] ?? 'Alert';
    final body = message.notification?.body ?? message.data['message'] ?? message.data['body'] ?? '';

    showSystemNotification(
      title: title,
      body: body,
      data: message.data,
    );
  }

  /// Get the token and send it to our backend
  Future<void> registerDeviceToken() async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _sendTokenToBackend(token);
      }

      // Also listen to token refreshes
      _fcm.onTokenRefresh.listen((newToken) {
        _sendTokenToBackend(newToken);
      });
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
    }
  }

  Future<void> _sendTokenToBackend(String token) async {
    try {
      await ApiClient.request(
        'POST',
        '/auth/fcm-token/',
        body: {'fcm_token': token},
      );
    } catch (e) {
      debugPrint('Error sending token to backend: $e');
    }
  }

  Future<void> scheduleOutpassReminder(DateTime expectedReturn) async {
    final DateTime reminderTime = expectedReturn.subtract(const Duration(minutes: 15));
    if (reminderTime.isBefore(DateTime.now())) return;

    const int notificationId = 1001; 
    
    await _localNotificationsPlugin.zonedSchedule(
      notificationId,
      'Outpass Expiring Soon',
      'Your outpass expires in 15 minutes. Please return to campus.',
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'This channel is used for important system alerts and notifications.',
          importance: Importance.max,
          priority: Priority.max,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelScheduledReminders() async {
    await _localNotificationsPlugin.cancel(1001);
  }
}
