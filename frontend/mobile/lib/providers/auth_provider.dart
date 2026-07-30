import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'api_client.dart';
import '../services/push_notification_service.dart';
import '../services/live_alert_service.dart';

enum AuthStatus { initial, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  String? _userRole;
  Map<String, dynamic>? _userData;

  AuthStatus get status => _status;
  String? get userRole => _userRole;
  Map<String, dynamic>? get userData => _userData;

  AuthProvider() {
    // Wire up the force-logout callback so ApiClient can trigger it on
    // unrecoverable 401s (e.g. refresh token expired).
    ApiClient.onForceLogout = () async {
      await logout();
    };
  }

  /// Called once at app startup. Checks for an existing valid session.
  Future<void> initialize() async {
    final token = await AuthService.getAccessToken();
    final refreshToken = await AuthService.getRefreshToken();
    if (token == null && refreshToken == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    // Try to validate the token by calling /auth/me/
    final res = await AuthService.getMe();
    if (res['success'] == true && res['data'] != null) {
      _userData = res['data'] is Map<String, dynamic>
          ? res['data'] as Map<String, dynamic>
          : null;
      _userRole = _userData?['role'] as String?;
      _status = AuthStatus.authenticated;
      
      // Register FCM token for the existing session & start live alert polling
      PushNotificationService().registerDeviceToken();
      LiveAlertService.startPolling();
    } else {
      // Token is invalid and refresh also failed (ApiClient handles that).
      await AuthService.clearTokens();
      _status = AuthStatus.unauthenticated;
      LiveAlertService.stopPolling();
    }
    notifyListeners();
  }

  /// Login and navigate to the correct dashboard.
  Future<Map<String, dynamic>> login(String email, String password, String role) async {
    final res = await AuthService.login(email, password, role);
    if (res['success'] == true) {
      _userRole = res['role'] as String? ?? role;

      // Fetch full user data
      final meRes = await AuthService.getMe();
      if (meRes['success'] == true && meRes['data'] != null) {
        _userData = meRes['data'] is Map<String, dynamic>
            ? meRes['data'] as Map<String, dynamic>
            : null;
      }

      _status = AuthStatus.authenticated;
      
      // Register FCM token for new login & start live alert polling
      PushNotificationService().registerDeviceToken();
      LiveAlertService.startPolling();
      
      notifyListeners();
    }
    return res;
  }

  /// Register student.
  Future<Map<String, dynamic>> registerStudent({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String registerNumber = '',
    String block = '',
    String department = '',
    int? year,
    String roomNumber = '',
  }) async {
    return await AuthService.registerStudent(
      name: name,
      email: email,
      password: password,
      phone: phone,
      registerNumber: registerNumber,
      block: block,
      department: department,
      year: year,
      roomNumber: roomNumber,
    );
  }

  /// Register warden.
  Future<Map<String, dynamic>> registerWarden({
    required String email,
    required String firstName,
    required String password,
    required String employeeId,
    String lastName = '',
    String hostelName = '',
    String phoneNumber = '',
  }) async {
    return await AuthService.wardenSignup(
      email: email,
      firstName: firstName,
      password: password,
      employeeId: employeeId,
      lastName: lastName,
      hostelName: hostelName,
      phoneNumber: phoneNumber,
    );
  }

  /// Logout — clear tokens and reset state.
  Future<void> logout() async {
    await AuthService.logout();
    LiveAlertService.stopPolling();
    _status = AuthStatus.unauthenticated;
    _userRole = null;
    _userData = null;
    notifyListeners();
  }

  /// Helper to get the dashboard route for the current role.
  String get dashboardRoute {
    switch (_userRole) {
      case 'warden':
      case 'admin_warden':
      case 'admin':
        return '/warden-dashboard';
      case 'watchman':
        return '/watchman-dashboard';
      case 'student':
      default:
        return '/student-dashboard';
    }
  }
}
