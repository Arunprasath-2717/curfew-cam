import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/warden_service.dart';

class OutsideStudentsScreen extends StatefulWidget {
  const OutsideStudentsScreen({super.key});

  @override
  State<OutsideStudentsScreen> createState() => _OutsideStudentsScreenState();
}

class _OutsideStudentsScreenState extends State<OutsideStudentsScreen> {
  bool _loading = true;
  List<dynamic> _students = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await WardenService.getOutsideStudents();
    if (mounted) {
      setState(() {
        _loading = false;
        if (res['success'] == true && res['data'] is List) {
          _students = res['data'] as List;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Outside Students')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _students.isEmpty
                  ? ListView(children: [Center(child: Text('No students outside', style: AppTextStyles.bodySecondary))])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _students.length,
                      itemBuilder: (context, i) {
                        final item = Map<String, dynamic>.from(_students[i]);
                        return Card(
                          child: ListTile(
                            title: Row(
                              children: [
                                Text(item['student_name'] ?? 'Student'),
                                if (item['student_on_campus'] == true)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Icon(Icons.verified, color: Colors.green, size: 16),
                                  ),
                              ],
                            ),
                            subtitle: Text('${item['destination'] ?? ''} • ${item['student_register'] ?? ''}'),
                            trailing: item['is_late'] == true ? const Icon(Icons.warning, color: Colors.red) : null,
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
