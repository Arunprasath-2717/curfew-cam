import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const Duration _requestTimeout = Duration(seconds: 10);

  /// Automatically picks the right host for Android emulator vs physical device.
  /// - Android emulator: 10.0.2.2 (maps to host machine's localhost)
  /// - Physical device / iOS simulator / other: localhost
  static String? _overrideBaseUrl;
  static void setOverrideBaseUrl(String url) => _overrideBaseUrl = url;

  static String get baseUrl {
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!;
    }

    const port = '8000';
    const apiPrefix = '/api/v1';

    if (kIsWeb) {
      return 'http://localhost:$port$apiPrefix';
    }

    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:$port$apiPrefix';
      }
    } catch (_) {}

    return 'http://127.0.0.1:$port$apiPrefix';
  }

  // ---------------------------------------------------------------------------
  // Token management
  // ---------------------------------------------------------------------------

  static Future<void> _migrateLegacyToken(String key) async {
    final secureValue = await _secureStorage.read(key: key);
    if (secureValue != null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final legacyValue = prefs.getString(key);
    if (legacyValue != null && legacyValue.isNotEmpty) {
      await _secureStorage.write(key: key, value: legacyValue);
      await prefs.remove(key);
    }
  }

  static Future<void> saveTokens(String access, String refresh) async {
    await _secureStorage.write(key: 'access_token', value: access);
    await _secureStorage.write(key: 'refresh_token', value: refresh);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  static Future<void> clearTokens() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  static Future<String?> getAccessToken() async {
    await _migrateLegacyToken('access_token');
    return _secureStorage.read(key: 'access_token');
  }

  static Future<String?> getRefreshToken() async {
    await _migrateLegacyToken('refresh_token');
    return _secureStorage.read(key: 'refresh_token');
  }

  static void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[AuthService] $message');
    }
  }

  static Map<String, dynamic> _formatResponse(http.Response res) {
    final contentType = res.headers['content-type'] ?? '';
    final isJson = contentType.contains('application/json') || contentType.contains('application/problem+json');

    dynamic decoded;
    if (isJson) {
      try {
        decoded = jsonDecode(res.body);
      } catch (_) {
        decoded = {'raw_body': res.body};
      }
    } else {
      decoded = {'raw_body': res.body};
    }

    final success = res.statusCode >= 200 && res.statusCode < 300;
    final message = decoded is Map
        ? (decoded['error'] ?? decoded['message'] ?? decoded['detail'] ?? (isJson ? 'Request failed' : 'Server returned a non-JSON response'))
        : (isJson ? 'Request failed' : 'Server returned a non-JSON response');

    return {
      'success': success,
      'statusCode': res.statusCode,
      'data': success ? ApiClient.extractData(decoded) : null,
      'message': message.toString(),
      'raw': decoded,
    };
  }

  static Future<Map<String, dynamic>> _sendJsonRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool retry = true,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final requestHeaders = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };

    _debugLog('$method $uri');

    try {
      late final http.Response res;
      switch (method) {
        case 'POST':
          res = await http.post(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(_requestTimeout);
          break;
        case 'PATCH':
          res = await http.patch(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(_requestTimeout);
          break;
        case 'PUT':
          res = await http.put(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(_requestTimeout);
          break;
        case 'DELETE':
          res = await http.delete(uri, headers: requestHeaders).timeout(_requestTimeout);
          break;
        default:
          res = await http.get(uri, headers: requestHeaders).timeout(_requestTimeout);
      }

      _debugLog('$method $uri -> ${res.statusCode} ${res.body.substring(0, res.body.length.clamp(0, 500).toInt())}');
      return _formatResponse(res);
    } on TimeoutException catch (error) {
      if (retry) {
        _debugLog('$method $uri timed out, retrying once');
        return _sendJsonRequest(method, endpoint, body: body, headers: headers, retry: false);
      }
      _debugLog('$method $uri timed out: $error');
      return {
        'success': false,
        'statusCode': 408,
        'message': 'Request timed out, check your connection',
      };
    } on SocketException catch (error) {
      if (retry) {
        _debugLog('$method $uri socket error, retrying once: $error');
        return _sendJsonRequest(method, endpoint, body: body, headers: headers, retry: false);
      }
      _debugLog('$method $uri socket error: $error');
      return {
        'success': false,
        'statusCode': 503,
        'message': 'Network error, check your connection',
      };
    } on http.ClientException catch (error) {
      if (retry) {
        _debugLog('$method $uri client error, retrying once: $error');
        return _sendJsonRequest(method, endpoint, body: body, headers: headers, retry: false);
      }
      _debugLog('$method $uri client error: $error');
      return {
        'success': false,
        'statusCode': 503,
        'message': 'Network error, check your connection',
      };
    }
  }

  // ---------------------------------------------------------------------------
  // Auth endpoints
  // ---------------------------------------------------------------------------

  static Future<Map<String, dynamic>> login(String identifier, String password, String role) async {
    final response = await _sendJsonRequest(
      'POST',
      '/auth/login/',
      body: {'email': identifier, 'password': password, 'role': role},
    );

    if (response['success'] == true) {
      final payload = response['data'];
      if (payload is! Map<String, dynamic>) {
        return {
          'success': false,
          'message': 'Login response had an unexpected format',
        };
      }

      final tokens = payload['tokens'];
      if (tokens is! Map) {
        return {
          'success': false,
          'message': 'Login response is missing token data',
        };
      }

      final access = tokens['access']?.toString();
      final refresh = tokens['refresh']?.toString();

      if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
        return {
          'success': false,
          'message': 'Login response is missing access or refresh token',
        };
      }

      await saveTokens(access, refresh);
      return {
        'success': true,
        'role': payload['role']?.toString() ?? role,
        'user': payload['user'],
      };
    }

    return {
      'success': false,
      'message': response['message']?.toString() ?? 'Login failed',
      'statusCode': response['statusCode'],
    };
  }

  static Future<Map<String, dynamic>> registerStudent({
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
    final response = await _sendJsonRequest(
      'POST',
      '/auth/register/student/',
      body: {
        'name': name,
        'email': email,
        'password': password,
        if (phone.isNotEmpty) 'phone_number': phone,
        if (registerNumber.isNotEmpty) 'register_number': registerNumber,
        if (block.isNotEmpty) 'block': block,
        if (department.isNotEmpty) 'department': department,
        if (year != null) 'year': year,
        if (roomNumber.isNotEmpty) 'room_number': roomNumber,
      },
    );

    if (response['success'] == true) {
      return {
        'success': true,
        'message': response['message']?.toString() ?? 'Registration successful',
      };
    }

    return {
      'success': false,
      'message': response['message']?.toString() ?? 'Registration failed',
      'statusCode': response['statusCode'],
    };
  }

  static Future<bool> logout() async {
    try {
      final token = await getAccessToken();
      final refresh = await getRefreshToken();
      if (token != null && refresh != null) {
        await _sendJsonRequest(
          'POST',
          '/auth/logout/',
          headers: {'Authorization': 'Bearer $token'},
          body: {'refresh': refresh},
        );
      }
    } catch (_) {}
    await clearTokens();
    return true;
  }

  static Future<Map<String, dynamic>> getMe() async {
    final res = await ApiClient.request('GET', '/auth/me/');
    if (res['success'] == true && res['data'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('ag_user', jsonEncode(res['data']));
    }
    return res;
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    return ApiClient.request('PATCH', '/auth/profile/', body: data);
  }

  /// Upload a profile photo via multipart PATCH to /auth/profile/.
  /// Returns the same success/message/data map as other AuthService methods.
  static Future<Map<String, dynamic>> uploadAvatar(File imageFile) async {
    try {
      final token = await getAccessToken();
      final uri = Uri.parse('$baseUrl/auth/profile/');
      final request = http.MultipartRequest('PATCH', uri);
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(
        await http.MultipartFile.fromPath('avatar', imageFile.path),
      );
      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamed);
      return _formatResponse(response);
    } on TimeoutException {
      return {'success': false, 'message': 'Upload timed out'};
    } on SocketException {
      return {'success': false, 'message': 'Network error during upload'};
    } catch (e) {
      return {'success': false, 'message': 'Upload failed: $e'};
    }
  }

  static Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    return ApiClient.request('POST', '/auth/change-password/', body: {
      'old_password': currentPassword,
      'new_password': newPassword,
      'new_password2': newPassword,
    });
  }

  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    // This is still used for email verification during sign-up
    return _sendJsonRequest(
      'POST',
      '/auth/verify-otp/',
      body: {'email': email, 'otp': otp, 'purpose': 'email_verification'},
    );
  }

  static Future<Map<String, dynamic>> wardenSignup({
    required String email,
    required String firstName,
    required String password,
    required String employeeId,
    String lastName = '',
    String hostelName = '',
    String phoneNumber = '',
  }) async {
    final response = await _sendJsonRequest(
      'POST',
      '/wardens/setup/signup/',
      body: {
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
        'employee_id': employeeId,
        'hostel_name': hostelName,
        'phone_number': phoneNumber,
      },
    );

    if (response['success'] == true) {
      return {
        'success': true,
        'message': response['message']?.toString() ?? 'Registration successful',
      };
    }

    return {
      'success': false,
      'message': response['message']?.toString() ?? 'Registration failed',
      'statusCode': response['statusCode'],
    };
  }
}
