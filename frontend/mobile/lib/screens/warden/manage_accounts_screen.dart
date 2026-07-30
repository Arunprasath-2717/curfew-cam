import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/warden_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../widgets/primary_button.dart';

class ManageAccountsScreen extends StatefulWidget {
  const ManageAccountsScreen({super.key});

  @override
  State<ManageAccountsScreen> createState() => _ManageAccountsScreenState();
}

class _ManageAccountsScreenState extends State<ManageAccountsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  bool _isMainWarden = false;
  
  List<dynamic> _students = [];
  List<dynamic> _wardens = [];
  List<dynamic> _auditLogs = [];

  @override
  void initState() {
    super.initState();
    _initRoleAndData();
  }

  Future<void> _initRoleAndData() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('ag_user');
    if (userStr != null) {
      try {
        final userObj = jsonDecode(userStr);
        _isMainWarden = userObj['is_main_warden'] == true;
      } catch (_) {}
    }
    
    _tabController = TabController(length: _isMainWarden ? 3 : 2, vsync: this);
    setState(() {});
    
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final stRes = await WardenService.getStudentsManaged();
      Map<String, dynamic>? waRes;
      if (_isMainWarden) {
        waRes = await WardenService.getWardensManaged();
      }
      final auRes = await WardenService.getAuditLogs();
      
      if (mounted) {
        setState(() {
          if (stRes['success'] == true) _students = stRes['data'] ?? [];
          if (waRes != null && waRes['success'] == true) _wardens = waRes['data'] ?? [];
          if (auRes['success'] == true) _auditLogs = auRes['data'] ?? [];
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteStudent(String id) async {
    final confirm = await _showConfirmDialog();
    if (confirm != true) return;
    
    setState(() => _loading = true);
    final res = await WardenService.deleteStudent(id);
    if (res['success'] == true) {
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student deleted successfully')));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Error')));
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteWarden(String id) async {
    final confirm = await _showConfirmDialog();
    if (confirm != true) return;
    
    setState(() => _loading = true);
    final res = await WardenService.deleteWarden(id);
    if (res['success'] == true) {
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Warden deleted successfully')));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Error')));
      setState(() => _loading = false);
    }
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('This will permanently delete this account and cannot be undone. Proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      )
    );
  }

  void _showAddAccountSheet(bool isStudent) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddAccountForm(isStudent: isStudent, onAdded: _loadData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Manage Accounts', style: AppTextStyles.screenTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.accentBlue,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accentBlue,
          tabs: [
            const Tab(text: 'Students'),
            if (_isMainWarden) const Tab(text: 'Wardens'),
            const Tab(text: 'Activity Log'),
          ],
        ),
      ),
      body: _loading && _students.isEmpty && _wardens.isEmpty && _auditLogs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_students, true),
                if (_isMainWarden) _buildList(_wardens, false),
                _buildAuditLogs(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          final isActivityLogTab = _isMainWarden ? _tabController.index == 2 : _tabController.index == 1;
          if (isActivityLogTab) {
            _tabController.animateTo(0);
          } else {
            // Index 0 is always students. Index 1 (if main warden) is wardens.
            _showAddAccountSheet(_tabController.index == 0);
          }
        },
      ),
    );
  }

  Future<void> _showBulkImportDialog() async {
    final controller = TextEditingController(
      text: 'email,first_name,last_name,register_number,department,year,hostel_block,room_number\n'
            'john@example.com,John,Doe,2024CS01,CSE,1,BH1,101\n'
            'jane@example.com,Jane,Smith,2024CS02,CSE,1,BH1,102',
    );

    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bulk Import CSV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Paste CSV data (email, first_name, last_name, register_number, department, year, hostel_block, room_number):', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 8,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Import CSV'),
          ),
        ],
      ),
    );

    if (res == true && controller.text.trim().isNotEmpty) {
      setState(() => _loading = true);
      final importRes = await WardenService.bulkImportStudents(controller.text.trim());
      if (importRes['success'] == true) {
        _loadData();
        if (mounted) {
          final data = importRes['data'] ?? {};
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import complete: ${data['created']} created, ${data['updated']} updated')),
          );
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(importRes['message'] ?? 'Import failed')));
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _runPromotion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yearly Promotion'),
        content: const Text('This will increment the year for 1st, 2nd, and 3rd year students. Proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Promote All')),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      final res = await WardenService.runPromotion();
      if (res['success'] == true) {
        _loadData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yearly promotion completed successfully')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Error')));
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _deletePassedOutStudents() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Passed Out Students'),
        content: const Text('This will permanently delete all 4th year / graduated student accounts. Proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete 4th Years', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _loading = true);
      final res = await WardenService.deletePassedOutStudents();
      if (res['success'] == true) {
        _loadData();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passed-out student accounts deleted')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Error')));
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildList(List<dynamic> items, bool isStudent) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isStudent) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showBulkImportDialog,
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: const Text('CSV Bulk Import'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _runPromotion,
                    icon: const Icon(Icons.school, size: 16),
                    label: const Text('Yearly Promotion'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _deletePassedOutStudents,
                    icon: const Icon(Icons.delete_sweep, size: 16, color: AppColors.error),
                    label: const Text('Delete 4th Yrs', style: TextStyle(color: AppColors.error)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(child: Text('No records found', style: AppTextStyles.bodySecondary)),
            )
          else
            ...List.generate(items.length, (index) {
              final item = items[index];
              final user = item['user'] ?? {};
              final name = user['first_name'] != null ? '${user['first_name']} ${user['last_name'] ?? ''}'.trim() : 'Unknown';
              final email = user['email'] ?? '';
              
              final subtitle = isStudent 
                  ? '${item['register_number']} | Year ${item['year'] ?? 1} | ${item['department']}' 
                  : '${item['employee_id']} | ${item['hostel_name']}';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.surfaceElevated,
                        child: Text(name.isNotEmpty ? name[0] : 'U', style: const TextStyle(color: AppColors.navy)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold)),
                            Text(email, style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(subtitle, style: AppTextStyles.bodySecondary.copyWith(fontSize: 12, color: AppColors.accentBlue)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () => isStudent ? _deleteStudent(item['id']) : _deleteWarden(item['id']),
                      )
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAuditLogs() {
    if (_auditLogs.isEmpty) {
      return Center(child: Text('No activity found', style: AppTextStyles.bodySecondary));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _auditLogs.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final log = _auditLogs[index];
          final action = log['action'] ?? '';
          final date = DateTime.tryParse(log['timestamp'] ?? '');
          final formattedDate = date != null ? DateFormat('MMM dd, yyyy HH:mm').format(date) : '';
          
          IconData icon;
          Color color;
          
          if (action.contains('create')) {
            icon = Icons.add_circle_outline;
            color = AppColors.success;
          } else {
            icon = Icons.remove_circle_outline;
            color = AppColors.error;
          }

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, color: color),
            title: Text('${log['performed_by_name']} $action', style: AppTextStyles.bodyMain),
            subtitle: Text('Target: ${log['target_email']}\n$formattedDate', style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
            isThreeLine: true,
          );
        },
      ),
    );
  }
}

class _AddAccountForm extends StatefulWidget {
  final bool isStudent;
  final VoidCallback onAdded;
  
  const _AddAccountForm({required this.isStudent, required this.onAdded});

  @override
  State<_AddAccountForm> createState() => _AddAccountFormState();
}

class _AddAccountFormState extends State<_AddAccountForm> {
  final _formKey = GlobalKey<FormState>();
  
  String _firstName = '';
  String _lastName = '';
  String _email = '';
  String _password = '';
  
  // Student
  String _regNo = '';
  String _dept = '';
  String _year = '1';
  
  // Warden
  String _empId = '';
  String _hostelName = '';
  
  bool _loading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _loading = true);
    
    Map<String, dynamic> data = {
      'first_name': _firstName,
      'last_name': _lastName,
      'email': _email,
      'password': _password,
    };
    
    if (widget.isStudent) {
      data.addAll({
        'register_number': _regNo,
        'department': _dept,
        'year': int.tryParse(_year) ?? 1,
      });
    } else {
      data.addAll({
        'employee_id': _empId,
        'hostel_name': _hostelName,
      });
    }
    
    final res = widget.isStudent 
        ? await WardenService.createStudent(data)
        : await WardenService.createWarden(data);
        
    setState(() => _loading = false);
    
    if (res['success'] == true) {
      if (!mounted) return;
      Navigator.pop(context);
      widget.onAdded();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.isStudent ? 'Add Student' : 'Add Warden', style: AppTextStyles.screenTitle),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _buildField('First Name', (v) => _firstName = v!)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField('Last Name (Optional)', (v) => _lastName = v!, required: false)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildField('Email', (v) => _email = v!),
                  const SizedBox(height: 16),
                  _buildField('Password', (v) => _password = v!, obscure: true),
                  const SizedBox(height: 16),
                  
                  if (widget.isStudent) ...[
                    Row(
                      children: [
                        Expanded(child: _buildField('Register Number', (v) => _regNo = v!)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildField('Year (1-5)', (v) => _year = v!)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildField('Department', (v) => _dept = v!),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(child: _buildField('Employee ID', (v) => _empId = v!)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildField('Hostel Name', (v) => _hostelName = v!)),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Create Account',
                    onPressed: _submit,
                    isLoading: _loading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, void Function(String?) onSave, {bool obscure = false, bool required = true}) {
    return TextFormField(
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
      onSaved: onSave,
    );
  }
}
