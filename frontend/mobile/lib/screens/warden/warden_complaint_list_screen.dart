import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../models/complaint_model.dart';
import '../../services/complaint_service.dart';

class WardenComplaintListScreen extends StatefulWidget {
  const WardenComplaintListScreen({super.key});

  @override
  State<WardenComplaintListScreen> createState() => _WardenComplaintListScreenState();
}

class _WardenComplaintListScreenState extends State<WardenComplaintListScreen> {
  List<ComplaintModel> _complaints = [];
  ComplaintStats? _stats;
  bool _isLoading = true;

  String _selectedStatus = 'all';
  String _selectedCategory = 'all';
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  final Map<String, Map<String, dynamic>> _statusConfig = {
    'all': {'label': 'All', 'color': AppColors.navy},
    'pending': {'label': 'Pending', 'color': AppColors.amber},
    'in_progress': {'label': 'In Progress', 'color': AppColors.accentBlue},
    'resolved': {'label': 'Resolved', 'color': AppColors.success},
    'rejected': {'label': 'Rejected', 'color': AppColors.error},
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final statsFuture = ComplaintService.fetchStats();
      final listFuture = ComplaintService.fetchComplaints(
        status: _selectedStatus,
        category: _selectedCategory,
        search: _searchQuery,
      );

      final stats = await statsFuture;
      final list = await listFuture;

      setState(() {
        _stats = stats;
        _complaints = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showStatusUpdateModal(ComplaintModel complaint) {
    String currentStatus = complaint.status;
    final TextEditingController responseController = TextEditingController(text: complaint.wardenResponse);
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text('Update Complaint Status', style: AppTextStyles.greeting.copyWith(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(complaint.title, style: AppTextStyles.bodySecondary.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // Status Selector Dropdown
                  const Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: currentStatus,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.swap_horizontal_circle),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                      DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                      DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => currentStatus = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Official Warden Response / Feedback Notes
                  const Text('Warden Feedback / Resolution Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: responseController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Enter action taken, notes for student, or resolution details...',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              setModalState(() => isSaving = true);
                              final res = await ComplaintService.updateComplaintStatus(
                                complaint.id,
                                status: currentStatus,
                                wardenResponse: responseController.text,
                              );
                              setModalState(() => isSaving = false);

                              if (mounted) {
                                Navigator.pop(context);
                                if (res['success'] == true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Complaint status updated!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                  _loadData();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(res['message'] ?? 'Update failed'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              }
                            },
                      child: isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save & Update', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logged Complaint Data'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Stats Summary Grid
              if (_stats != null) ...[
                Row(
                  children: [
                    _buildStatCard('Total Logged', '${_stats!.totalComplaints}', AppColors.navy, Icons.article),
                    const SizedBox(width: 10),
                    _buildStatCard('Pending', '${_stats!.pendingCount}', AppColors.amber, Icons.pending_actions),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildStatCard('In Progress', '${_stats!.inProgressCount}', AppColors.accentBlue, Icons.published_with_changes),
                    const SizedBox(width: 10),
                    _buildStatCard('Resolved', '${_stats!.resolvedCount}', AppColors.success, Icons.task_alt),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // 2. Search Box
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search complaints by title or student...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                            _loadData();
                          },
                        )
                      : null,
                ),
                onSubmitted: (val) {
                  setState(() => _searchQuery = val.trim());
                  _loadData();
                },
              ),
              const SizedBox(height: 16),

              // 3. Status Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statusConfig.entries.map((entry) {
                    final key = entry.key;
                    final label = entry.value['label'] as String;
                    final color = entry.value['color'] as Color;
                    final isSelected = _selectedStatus == key;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(label),
                        selected: isSelected,
                        selectedColor: color.withOpacity(0.2),
                        checkmarkColor: color,
                        labelStyle: TextStyle(
                          color: isSelected ? color : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setState(() => _selectedStatus = selected ? key : 'all');
                          _loadData();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // 4. Complaints List
              if (_isLoading)
                const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else if (_complaints.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        Icon(Icons.inbox, size: 48, color: AppColors.textSecondary.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        const Text('No complaints match the filter.', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _complaints.length,
                  itemBuilder: (context, index) {
                    final item = _complaints[index];
                    final statusColor = _statusConfig[item.status]?['color'] as Color? ?? AppColors.amber;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: primaryColor.withOpacity(0.1),
                                        child: Icon(
                                          item.isAnonymous ? Icons.person_off : Icons.person,
                                          size: 18,
                                          color: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.studentName,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                            if (!item.isAnonymous && item.studentRegisterNumber.isNotEmpty)
                                              Text(
                                                'Reg: ${item.studentRegisterNumber} • Room: ${item.studentRoom} (${item.studentBlock})',
                                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: statusColor),
                                  ),
                                  child: Text(
                                    item.statusDisplay,
                                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),

                            // Complaint Title & Category
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item.categoryDisplay,
                                    style: TextStyle(color: primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Priority: ${item.priorityDisplay}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Text(item.title, style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 6),
                            Text(item.description, style: AppTextStyles.bodySecondary),
                            const SizedBox(height: 12),

                            // Response details if any
                            if (item.wardenResponse.isNotEmpty) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Feedback: ${item.wardenResponse}',
                                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Action / Update Button (Disabled when completed/done)
                            Align(
                              alignment: Alignment.centerRight,
                              child: (item.status == 'resolved' || item.status == 'rejected')
                                  ? OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: AppColors.textSecondary.withOpacity(0.3)),
                                        backgroundColor: AppColors.surfaceElevated,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: Icon(
                                        item.status == 'resolved' ? Icons.check_circle : Icons.cancel,
                                        size: 16,
                                        color: item.status == 'resolved' ? AppColors.success : AppColors.error,
                                      ),
                                      label: Text(
                                        item.status == 'resolved' ? 'Done & Resolved' : 'Rejected & Closed',
                                        style: TextStyle(
                                          color: item.status == 'resolved' ? AppColors.success : AppColors.error,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      onPressed: null, // Disabled once completed
                                    )
                                  : OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: primaryColor),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: const Text('Review & Mark Done'),
                                      onPressed: () => _showStatusUpdateModal(item),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
