import 'api_client.dart';

class WardenService {
  static Future<Map<String, dynamic>> getDashboard() =>
      ApiClient.request('GET', '/wardens/dashboard/');

  static Future<Map<String, dynamic>> getPendingRequests() =>
      ApiClient.request('GET', '/wardens/pending/');

  static Future<Map<String, dynamic>> getOutpassDetail(String id) =>
      ApiClient.request('GET', '/outpass/$id/');

  static Future<Map<String, dynamic>> approveOutpass(String id, {String? notes}) =>
      ApiClient.request('POST', '/wardens/outpass/$id/approve/', body: {
        'action': 'approve',
        if (notes != null) 'warden_notes': notes,
      });

  static Future<Map<String, dynamic>> rejectOutpass(String id, String reason, {String? notes}) =>
      ApiClient.request('POST', '/wardens/outpass/$id/approve/', body: {
        'action': 'reject',
        'rejection_reason': reason,
        if (notes != null) 'warden_notes': notes,
      });

  static Future<Map<String, dynamic>> bulkApprove(List<String> ids) =>
      ApiClient.request('POST', '/outpass/bulk-approve/', body: {'outpass_ids': ids});

  static Future<Map<String, dynamic>> getOutsideStudents() =>
      ApiClient.request('GET', '/outpass/active/');

  static Future<Map<String, dynamic>> getLateStudents() =>
      ApiClient.request('GET', '/wardens/late-students/');

  static Future<Map<String, dynamic>> getReports(String period) =>
      ApiClient.request('GET', '/wardens/reports/?period=$period');

  static Future<Map<String, dynamic>> searchStudents(String query) =>
      ApiClient.request('GET', '/students/search/?q=${Uri.encodeComponent(query)}');

  static Future<Map<String, dynamic>> getStudentDirectory() =>
      ApiClient.request('GET', '/students/list/');

  static Future<Map<String, dynamic>> getStudentDetail(String id) =>
      ApiClient.request('GET', '/students/$id/');

  static Future<Map<String, dynamic>> getStudentViolations(String id) =>
      ApiClient.request('GET', '/students/$id/violations/');

  static Future<Map<String, dynamic>> sendEmergencyAlert(String title, String message) =>
      ApiClient.request('POST', '/notifications/emergency/', body: {
        'title': title,
        'message': message,
      });

  static Future<Map<String, dynamic>> getMovementLogs() =>
      ApiClient.request('GET', '/wardens/movement-logs/');

  static Future<Map<String, dynamic>> getHistory() =>
      ApiClient.request('GET', '/wardens/history/');

  static Future<Map<String, dynamic>> getCameraStatus() =>
      ApiClient.request('GET', '/camera/status/');

  static Future<Map<String, dynamic>> getDetectionAlerts() =>
      ApiClient.request('GET', '/detection/alerts/');

  static Future<Map<String, dynamic>> acknowledgeAlert(String alertId) =>
      ApiClient.request('POST', '/detection/alerts/$alertId/acknowledge/');

  static Future<Map<String, dynamic>> getStudentsManaged() =>
      ApiClient.request('GET', '/wardens/manage/students/');

  static Future<Map<String, dynamic>> createStudent(Map<String, dynamic> data) =>
      ApiClient.request('POST', '/wardens/manage/students/', body: data);

  static Future<Map<String, dynamic>> deleteStudent(String id) =>
      ApiClient.request('DELETE', '/wardens/manage/students/$id/');

  static Future<Map<String, dynamic>> getWardensManaged() =>
      ApiClient.request('GET', '/wardens/manage/wardens/');

  static Future<Map<String, dynamic>> createWarden(Map<String, dynamic> data) =>
      ApiClient.request('POST', '/wardens/manage/wardens/', body: data);

  static Future<Map<String, dynamic>> deleteWarden(String id) =>
      ApiClient.request('DELETE', '/wardens/manage/wardens/$id/');

  static Future<Map<String, dynamic>> getAuditLogs() =>
      ApiClient.request('GET', '/wardens/manage/audit-log/');

  static Future<Map<String, dynamic>> startDetectionStream() =>
      ApiClient.request('POST', '/detection/stream/start/');

  static Future<Map<String, dynamic>> stopDetectionStream() =>
      ApiClient.request('POST', '/detection/stream/stop/');
}
