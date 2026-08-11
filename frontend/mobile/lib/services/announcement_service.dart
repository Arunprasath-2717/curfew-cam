import '../providers/api_client.dart';

class AnnouncementService {
  static Future<Map<String, dynamic>> getAnnouncements() async {
    return await ApiClient.request('GET', '/notifications/announcements/');
  }

  static Future<Map<String, dynamic>> postAnnouncement(String title, String message, {int? durationHours}) async {
    final Map<String, dynamic> body = {
      'title': title,
      'message': message,
    };
    if (durationHours != null) {
      body['duration_hours'] = durationHours;
    }
    return await ApiClient.request('POST', '/notifications/announcements/', body: body);
  }

  static Future<Map<String, dynamic>> deleteAnnouncement(String id) async {
    return await ApiClient.request('DELETE', '/notifications/announcements/$id/');
  }
}
