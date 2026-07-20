import 'package:flutter/material.dart';
import '../../providers/watchman_service.dart';

class OverdueStudentsScreen extends StatefulWidget {
  const OverdueStudentsScreen({super.key});

  @override
  State<OverdueStudentsScreen> createState() => _OverdueStudentsScreenState();
}

class _OverdueStudentsScreenState extends State<OverdueStudentsScreen> {
  bool _loading = true;
  List<dynamic> _overdue = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await WatchmanService.getOverdueStudents();
    if (mounted) {
      setState(() {
        _loading = false;
        if (res['success'] == true && res['data'] is List) {
          _overdue = res['data'] as List;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overdue Students')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _overdue.isEmpty
                  ? ListView(children: const [Center(child: Text('No overdue students'))])
                  : ListView.builder(
                      itemCount: _overdue.length,
                      itemBuilder: (context, i) {
                        final s = Map<String, dynamic>.from(_overdue[i]);
                        return ListTile(
                          title: Text(s['student_name'] ?? 'Student'),
                          subtitle: Text('Due: ${s['expected_return_date'] ?? ''} ${s['expected_return_time'] ?? ''}'),
                          trailing: const Icon(Icons.warning, color: Colors.red),
                        );
                      },
                    ),
            ),
    );
  }
}
