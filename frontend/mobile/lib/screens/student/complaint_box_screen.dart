import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';
import '../../models/complaint_model.dart';
import '../../services/complaint_service.dart';

class ComplaintBoxScreen extends StatefulWidget {
  const ComplaintBoxScreen({super.key});

  @override
  State<ComplaintBoxScreen> createState() => _ComplaintBoxScreenState();
}

class _ComplaintBoxScreenState extends State<ComplaintBoxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedCategory = 'maintenance';
  String _selectedPriority = 'medium';
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  List<ComplaintModel> _myComplaints = [];
  bool _isLoadingComplaints = true;
  String? _errorMessage;

  final Map<String, String> _categories = {
    'maintenance': 'Maintenance / Repair',
    'food_mess': 'Food & Mess',
    'noise_discipline': 'Noise & Discipline',
    'security': 'Security & Safety',
    'facilities': 'Facilities & Amenities',
    'other': 'Other Issues',
  };

  final Map<String, Map<String, dynamic>> _priorityConfig = {
    'low': {'label': 'Low', 'color': AppColors.success},
    'medium': {'label': 'Medium', 'color': AppColors.accentBlue},
    'high': {'label': 'High', 'color': AppColors.amber},
    'urgent': {'label': 'Urgent', 'color': AppColors.error},
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadComplaints();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaints() async {
    setState(() => _isLoadingComplaints = true);
    try {
      final list = await ComplaintService.fetchComplaints();
      setState(() {
        _myComplaints = list;
        _isLoadingComplaints = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingComplaints = false;
        _errorMessage = 'Failed to load complaints.';
      });
    }
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final res = await ComplaintService.createComplaint(
      title: _titleController.text,
      category: _selectedCategory,
      priority: _selectedPriority,
      description: _descriptionController.text,
      isAnonymous: _isAnonymous,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Complaint submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context); // Move back to student home page
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to submit complaint.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'resolved':
        return AppColors.success;
      case 'in_progress':
        return AppColors.accentBlue;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Hostel Complaint Box', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.navy,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.navy,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.amber,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.edit_note, size: 20), text: 'Log Complaint'),
                Tab(icon: Icon(Icons.history, size: 20), text: 'My Complaints'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubmitForm(primaryColor),
          _buildMyComplaintsList(primaryColor),
        ],
      ),
    );
  }

  Widget _buildSubmitForm(Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.9), primaryColor.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.report_problem, color: Colors.white, size: 36),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Have an Issue?',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Submit your complaint to the warden office. Emergency issues will be prioritized.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Complaint Title
            Text('Complaint Title', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'e.g. Broken water tap in Room 302',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a title' : null,
            ),
            const SizedBox(height: 20),

            // Category Dropdown
            Text('Category', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 20),

            // Priority Selection
            Text('Priority Level', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: _priorityConfig.entries.map((entry) {
                final key = entry.key;
                final label = entry.value['label'] as String;
                final color = entry.value['color'] as Color;
                final isSelected = _selectedPriority == key;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: color,
                      backgroundColor: color.withOpacity(0.1),
                      onSelected: (bool selected) {
                        if (selected) setState(() => _selectedPriority = key);
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Description
            Text('Description / Details', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe the issue clearly (location, timing, severity)...',
                alignLabelWithHint: true,
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Please describe the issue' : null,
            ),
            const SizedBox(height: 20),

            // Anonymous Switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: AppColors.accentBlue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Submit Anonymously', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        const Text(
                          'Your name and register number will be hidden from public complaint logs.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAnonymous,
                    activeColor: primaryColor,
                    onChanged: (val) => setState(() => _isAnonymous = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Submit Button
            PrimaryButton(
              label: 'Submit Complaint',
              icon: Icons.send_rounded,
              isLoading: _isSubmitting,
              onPressed: _submitComplaint,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyComplaintsList(Color primaryColor) {
    if (_isLoadingComplaints) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myComplaints.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No Complaints Logged Yet', style: AppTextStyles.greeting.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'Use the "Log Complaint" tab to report any hostel issues.',
              style: AppTextStyles.bodySecondary,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadComplaints,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myComplaints.length,
        itemBuilder: (context, index) {
          final complaint = _myComplaints[index];
          final statusColor = _getStatusColor(complaint.status);
          final priorityColor = _priorityConfig[complaint.priority]?['color'] as Color? ?? AppColors.accentBlue;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Category Tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          complaint.categoryDisplay,
                          style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor, width: 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              complaint.statusDisplay,
                              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(complaint.title, style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),

                  // Description
                  Text(complaint.description, style: AppTextStyles.bodySecondary),
                  const SizedBox(height: 12),

                  // Meta Row
                  Row(
                    children: [
                      Icon(Icons.flag, size: 14, color: priorityColor),
                      const SizedBox(width: 4),
                      Text(
                        'Priority: ${complaint.priorityDisplay}',
                        style: TextStyle(color: priorityColor, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      if (complaint.isAnonymous)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Anonymous', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ),
                      const SizedBox(width: 8),
                      if (complaint.createdAt != null)
                        Text(
                          '${complaint.createdAt!.day}/${complaint.createdAt!.month}/${complaint.createdAt!.year}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                    ],
                  ),

                  // Warden Response Card
                  if (complaint.wardenResponse.isNotEmpty) ...[
                    const Divider(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.successGlow,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.success.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.admin_panel_settings, size: 16, color: AppColors.success),
                              const SizedBox(width: 6),
                              Text(
                                'Warden Response (${complaint.assignedWardenName ?? "Warden Office"})',
                                style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            complaint.wardenResponse,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
