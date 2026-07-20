import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

/// Completer used to serialize refresh attempts across concurrent requests.
Completer<bool>? _refreshCompleter;

class ApiClient {
  static const Duration _requestTimeout = Duration(seconds: 10);

  static String get baseUrl => AuthService.baseUrl;

  /// Global logout callback — set by AuthProvider on startup.
  static Future<void> Function()? onForceLogout;

  static void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[ApiClient] $message');
    }
  }

  static dynamic extractData(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body['success'] == true && body.containsKey('data')) {
        return body['data'];
      }
      if (body.containsKey('results')) {
        return body['results'];
      }
    }
    return body;
  }

  static Future<void> _waitForRefreshToFinish() async {
    final completer = _refreshCompleter;
    if (completer != null) {
      await completer.future;
    }
  }

  static Future<http.Response> _sendOnce(
    String method,
    Uri uri, {
    required Map<String, String> headers,
    Map<String, dynamic>? body,
  }) async {
    switch (method) {
      case 'POST':
        return http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null).timeout(_requestTimeout);
      case 'PATCH':
        return http.patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null).timeout(_requestTimeout);
      case 'PUT':
        return http.put(uri, headers: headers, body: body != null ? jsonEncode(body) : null).timeout(_requestTimeout);
      case 'DELETE':
        return http.delete(uri, headers: headers).timeout(_requestTimeout);
      default:
        return http.get(uri, headers: headers).timeout(_requestTimeout);
    }
  }

  static Future<Map<String, dynamic>> _attemptRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
    bool allowRetry = true,
  }) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await AuthService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final uri = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await _sendOnce(method, uri, headers: headers, body: body);
      final contentType = response.headers['content-type'] ?? '';
      final isJson = contentType.contains('application/json') || contentType.contains('application/problem+json');

      dynamic decoded;
      if (isJson) {
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          decoded = {'raw_body': response.body};
        }
      } else {
        decoded = {'raw_body': response.body};
      }

      _debugLog('$method $uri -> ${response.statusCode} ${response.body.substring(0, response.body.length.clamp(0, 500).toInt())}');

      final success = response.statusCode >= 200 && response.statusCode < 300;
      final message = decoded is Map
          ? (decoded['error'] ?? decoded['message'] ?? decoded['detail'] ?? (isJson ? 'Request failed' : 'Server returned a non-JSON response'))
          : (isJson ? 'Request failed' : 'Server returned a non-JSON response');

      return {
        'success': success,
        'statusCode': response.statusCode,
        'data': success ? extractData(decoded) : null,
        'message': message.toString(),
        'raw': decoded is Map || decoded is List ? decoded : response.body,
      };
    } on TimeoutException catch (error) {
      if (allowRetry) {
        _debugLog('$method $uri timed out, retrying once: $error');
        return _attemptRequest(method, endpoint, body: body, auth: auth, allowRetry: false);
      }
      return {
        'success': false,
        'statusCode': 408,
        'message': 'Request timed out, check your connection',
      };
    } on SocketException catch (error) {
      if (allowRetry) {
        _debugLog('$method $uri socket error, retrying once: $error');
        return _attemptRequest(method, endpoint, body: body, auth: auth, allowRetry: false);
      }
      return {
        'success': false,
        'statusCode': 503,
        'message': 'Network error, check your connection',
      };
    } on http.ClientException catch (error) {
      if (allowRetry) {
        _debugLog('$method $uri client error, retrying once: $error');
        return _attemptRequest(method, endpoint, body: body, auth: auth, allowRetry: false);
      }
      return {
        'success': false,
        'statusCode': 503,
        'message': 'Network error, check your connection',
      };
    }
  }

  static Future<bool> _tryRefreshToken() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    try {
      final refresh = await AuthService.getRefreshToken();
      if (refresh == null || refresh.isEmpty) {
        completer.complete(false);
        return false;
      }

      final refreshResult = await _attemptRequest(
        'POST',
        '/auth/refresh/',
        auth: false,
        body: {'refresh': refresh},
        allowRetry: true,
      );

      if (refreshResult['success'] == true && refreshResult['data'] is Map) {
        final data = Map<String, dynamic>.from(refreshResult['data'] as Map);
        final newAccess = data['access']?.toString();
        final newRefresh = data['refresh']?.toString() ?? refresh;
        if (newAccess != null && newAccess.isNotEmpty) {
          await AuthService.saveTokens(newAccess, newRefresh);
          _debugLog('POST $baseUrl/auth/refresh/ -> ${refreshResult['statusCode']} token refreshed');
          completer.complete(true);
          return true;
        }
      }

      _debugLog('POST $baseUrl/auth/refresh/ -> ${refreshResult['statusCode']} ${refreshResult['message']}');
      completer.complete(false);
      return false;
    } catch (error) {
      _debugLog('Refresh error: $error');
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      return false;
    } finally {
      if (_refreshCompleter == completer) {
        _refreshCompleter = null;
      }
    }
  }

  static Future<Map<String, dynamic>> request(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool auth = true,
  }) async {
    if (auth) {
      await _waitForRefreshToFinish();
    }

    final result = await _attemptRequest(method, endpoint, body: body, auth: auth);

    if (result['statusCode'] == 401 && auth) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        await _waitForRefreshToFinish();
        return _attemptRequest(method, endpoint, body: body, auth: auth, allowRetry: false);
      }

      if (onForceLogout != null) {
        await onForceLogout!();
      }
    }

    return result;
  }
}
