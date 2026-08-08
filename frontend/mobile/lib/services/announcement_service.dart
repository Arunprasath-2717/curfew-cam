import '../providers/api_client.dart';

class AnnouncementService {
  static Future<Map<String, dynamic>> getAnnouncements() async {
    return await ApiClient.request('GET', '/notifications/announcements/');
  }

  static Future<Map<String, dynamic>> postAnnouncement(String title, String message) async {
    return await ApiClient.request('POST', '/notifications/announcements/', body: {
      'title': title,
      'message': message,
    });
  }

  static Future<Map<String, dynamic>> deleteAnnouncement(String id) async {
    return await ApiClient.request('DELETE', '/notifications/announcements/$id/');
  }
}
