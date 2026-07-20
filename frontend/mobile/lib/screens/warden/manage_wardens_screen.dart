import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/warden_service.dart';
import '../../widgets/primary_button.dart';

class ManageWardensScreen extends StatefulWidget {
  const ManageWardensScreen({super.key});

  @override
  State<ManageWardensScreen> createState() => _ManageWardensScreenState();
}

class _ManageWardensScreenState extends State<ManageWardensScreen> {
  bool _loading = true;
  List<dynamic> _wardens = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final res = await WardenService.getWardensManaged();
      if (mounted) {
        setState(() {
          if (res['success'] == true) _wardens = res['data'] ?? [];
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteWarden(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Warden'),
        content: const Text('This will deactivate the warden account. Proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Deactivate', style: TextStyle(color: AppColors.error)),
          ),
        ],
      )
    );
    if (confirm != true) return;
    
    setState(() => _loading = true);
    final res = await WardenService.deleteWarden(id);
    if (res['success'] == true) {
      _loadData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Warden deactivated successfully')));
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Error')));
      setState(() => _loading = false);
    }
  }

  void _showAddAccountSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddWardenForm(onAdded: _loadData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Manage Wardens', style: AppTextStyles.screenTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyLarge?.color),
      ),
      body: _loading && _wardens.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _wardens.isEmpty
              ? Center(child: Text('No wardens found', style: AppTextStyles.bodySecondary))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _wardens.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _wardens[index];
                      final user = item['user'] ?? {};
                      final name = user['first_name'] != null ? '${user['first_name']} ${user['last_name'] ?? ''}'.trim() : 'Unknown';
                      final email = user['email'] ?? '';
                      final subtitle = '${item['employee_id']} | ${item['hostel_name'] ?? 'No Hostel'}';

                      return Container(
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
                              onPressed: () => _deleteWarden(item['id']),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.error,
        onPressed: _showAddAccountSheet,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _AddWardenForm extends StatefulWidget {
  final VoidCallback onAdded;
  
  const _AddWardenForm({required this.onAdded});

  @override
  State<_AddWardenForm> createState() => _AddWardenFormState();
}

class _AddWardenFormState extends State<_AddWardenForm> {
  final _formKey = GlobalKey<FormState>();
  
  String _firstName = '';
  String _lastName = '';
  String _email = '';
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
      'employee_id': _empId,
      'hostel_name': _hostelName,
    };
    
    final res = await WardenService.createWarden(data);
        
    setState(() => _loading = false);
    
    if (res['success'] == true) {
      if (!mounted) return;
      Navigator.pop(context);
      widget.onAdded();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Warden invited successfully. An email has been sent.')));
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
                  Text('Invite Warden', style: AppTextStyles.screenTitle),
                  const SizedBox(height: 8),
                  Text('An email invite will be sent to them to set their password.', style: AppTextStyles.bodySecondary),
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
                  Row(
                    children: [
                      Expanded(child: _buildField('Employee ID', (v) => _empId = v!)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildField('Hostel Name (Optional)', (v) => _hostelName = v!, required: false)),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Send Invite',
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

  Widget _buildField(String label, void Function(String?) onSave, {bool required = true}) {
    return TextFormField(
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
