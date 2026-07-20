import 'api_client.dart';

class WatchmanService {
  static Future<Map<String, dynamic>> getDashboard() =>
      ApiClient.request('GET', '/watchmen/dashboard/');

  static Future<Map<String, dynamic>> scanQr(String qrToken, String scanType, {String? gate}) =>
      ApiClient.request('POST', '/watchmen/scan/', body: {
        'qr_token': qrToken,
        'scan_type': scanType,
        if (gate != null) 'gate': gate,
      });

  static Future<Map<String, dynamic>> manualVerify(String registerNumber, String scanType) =>
      ApiClient.request('POST', '/watchmen/manual-verify/', body: {
        'register_number': registerNumber,
        'scan_type': scanType,
      });

  static Future<Map<String, dynamic>> getActivePasses() =>
      ApiClient.request('GET', '/watchmen/active-passes/');

  static Future<Map<String, dynamic>> getOverdueStudents() =>
      ApiClient.request('GET', '/watchmen/overdue/');

  static Future<Map<String, dynamic>> getShiftSummary() =>
      ApiClient.request('GET', '/watchmen/shift-summary/');

  static Future<Map<String, dynamic>> getScanLogs() =>
      ApiClient.request('GET', '/watchmen/logs/');

  static Future<Map<String, dynamic>> startShift({String? gate}) =>
      ApiClient.request('POST', '/watchmen/shift/start/', body: {if (gate != null) 'gate': gate});

  static Future<Map<String, dynamic>> endShift({String? notes}) =>
      ApiClient.request('POST', '/watchmen/shift/end/', body: {if (notes != null) 'notes': notes});
}
