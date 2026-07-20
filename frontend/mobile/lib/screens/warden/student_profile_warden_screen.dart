import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/warden_service.dart';

class StudentProfileWardenScreen extends StatefulWidget {
  const StudentProfileWardenScreen({super.key});

  @override
  State<StudentProfileWardenScreen> createState() => _StudentProfileWardenScreenState();
}

class _StudentProfileWardenScreenState extends State<StudentProfileWardenScreen> {
  bool _loading = true;
  Map<String, dynamic>? _student;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    final res = await WardenService.getStudentDetail(id);
    if (mounted) {
      setState(() {
        _loading = false;
        if (res['success'] == true) _student = Map<String, dynamic>.from(res['data']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _student?['user'] as Map<String, dynamic>?;
    return Scaffold(
      appBar: AppBar(title: const Text('Student Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _student == null
              ? Center(child: Text('Not found', style: AppTextStyles.bodyMain))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?['full_name'] ?? user?['first_name'] ?? 'Student', style: AppTextStyles.screenTitle),
                      Text('Reg: ${_student!['register_number'] ?? ''}', style: AppTextStyles.bodySecondary),
                      Text('Dept: ${_student!['department'] ?? ''}', style: AppTextStyles.bodyMain),
                      Text('Block: ${_student!['hostel_block'] ?? ''} Room ${_student!['room_number'] ?? ''}', style: AppTextStyles.bodyMain),
                      Text('Status: ${_student!['is_in_hostel'] == true ? 'In Hostel' : 'Outside'}', style: AppTextStyles.bodyMain),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/violations', arguments: _student!['id']),
                        child: const Text('View Violations'),
                      ),
                    ],
                  ),
                ),
    );
  }
}
