class ComplaintModel {
  final String id;
  final String title;
  final String category;
  final String categoryDisplay;
  final String priority;
  final String priorityDisplay;
  final String description;
  final String status;
  final String statusDisplay;
  final bool isAnonymous;
  final String wardenResponse;
  final String? assignedWardenName;
  final String studentName;
  final String studentRegisterNumber;
  final String studentRoom;
  final String studentBlock;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  ComplaintModel({
    required this.id,
    required this.title,
    required this.category,
    required this.categoryDisplay,
    required this.priority,
    required this.priorityDisplay,
    required this.description,
    required this.status,
    required this.statusDisplay,
    required this.isAnonymous,
    required this.wardenResponse,
    this.assignedWardenName,
    required this.studentName,
    required this.studentRegisterNumber,
    required this.studentRoom,
    required this.studentBlock,
    this.createdAt,
    this.resolvedAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? 'other',
      categoryDisplay: json['category_display']?.toString() ?? 'Other',
      priority: json['priority']?.toString() ?? 'medium',
      priorityDisplay: json['priority_display']?.toString() ?? 'Medium',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      statusDisplay: json['status_display']?.toString() ?? 'Pending',
      isAnonymous: json['is_anonymous'] == true,
      wardenResponse: json['warden_response']?.toString() ?? '',
      assignedWardenName: json['assigned_warden_name']?.toString(),
      studentName: json['student_name']?.toString() ?? 'Student',
      studentRegisterNumber: json['student_register_number']?.toString() ?? '',
      studentRoom: json['student_room']?.toString() ?? '',
      studentBlock: json['student_block']?.toString() ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      resolvedAt: json['resolved_at'] != null ? DateTime.tryParse(json['resolved_at'].toString()) : null,
    );
  }
}

class ComplaintStats {
  final int totalComplaints;
  final int pendingCount;
  final int inProgressCount;
  final int resolvedCount;
  final int rejectedCount;
  final Map<String, int> categoryBreakdown;

  ComplaintStats({
    required this.totalComplaints,
    required this.pendingCount,
    required this.inProgressCount,
    required this.resolvedCount,
    required this.rejectedCount,
    required this.categoryBreakdown,
  });

  factory ComplaintStats.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['category_breakdown'];
    final Map<String, int> breakdown = {};
    if (rawBreakdown is Map) {
      rawBreakdown.forEach((key, val) {
        breakdown[key.toString()] = (val is int) ? val : int.tryParse(val.toString()) ?? 0;
      });
    }

    return ComplaintStats(
      totalComplaints: json['total_complaints'] ?? 0,
      pendingCount: json['pending_count'] ?? 0,
      inProgressCount: json['in_progress_count'] ?? 0,
      resolvedCount: json['resolved_count'] ?? 0,
      rejectedCount: json['rejected_count'] ?? 0,
      categoryBreakdown: breakdown,
    );
  }
}
