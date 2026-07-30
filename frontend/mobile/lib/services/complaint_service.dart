import '../providers/api_client.dart';
import '../models/complaint_model.dart';

class ComplaintService {
  static Future<List<ComplaintModel>> fetchComplaints({
    String? status,
    String? category,
    String? priority,
    String? search,
  }) async {
    final queryParams = <String>[];
    if (status != null && status.isNotEmpty && status != 'all') {
      queryParams.add('status=$status');
    }
    if (category != null && category.isNotEmpty && category != 'all') {
      queryParams.add('category=$category');
    }
    if (priority != null && priority.isNotEmpty && priority != 'all') {
      queryParams.add('priority=$priority');
    }
    if (search != null && search.isNotEmpty) {
      queryParams.add('search=${Uri.encodeComponent(search)}');
    }

    final query = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final res = await ApiClient.request('GET', '/complaints/$query');

    if (res['success'] == true && res['data'] != null) {
      dynamic raw = res['data'];
      if (raw is Map && raw.containsKey('results')) {
        raw = raw['results'];
      }
      if (raw is List) {
        return raw.map((item) => ComplaintModel.fromJson(Map<String, dynamic>.from(item))).toList();
      }
    }
    return [];
  }

  static Future<Map<String, dynamic>> createComplaint({
    required String title,
    required String category,
    required String priority,
    required String description,
    required bool isAnonymous,
  }) async {
    final body = {
      'title': title,
      'category': category,
      'priority': priority,
      'description': description,
      'is_anonymous': isAnonymous,
    };
    return ApiClient.request('POST', '/complaints/', body: body);
  }

  static Future<Map<String, dynamic>> updateComplaintStatus(
    String id, {
    required String status,
    String? wardenResponse,
  }) async {
    final body = {
      'status': status,
      if (wardenResponse != null) 'warden_response': wardenResponse,
    };
    return ApiClient.request('PATCH', '/complaints/$id/status/', body: body);
  }

  static Future<ComplaintStats?> fetchStats() async {
    final res = await ApiClient.request('GET', '/complaints/stats/');
    if (res['success'] == true && res['data'] is Map) {
      return ComplaintStats.fromJson(Map<String, dynamic>.from(res['data']));
    }
    return null;
  }
}
