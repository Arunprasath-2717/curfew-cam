import 'package:flutter/material.dart';
import '../../providers/warden_service.dart';

class StudentDirectoryScreen extends StatefulWidget {
  const StudentDirectoryScreen({super.key});

  @override
  State<StudentDirectoryScreen> createState() => _StudentDirectoryScreenState();
}

class _StudentDirectoryScreenState extends State<StudentDirectoryScreen> {
  bool _loading = true;
  List<dynamic> _students = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await WardenService.getStudentDirectory();
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
      appBar: AppBar(
        title: const Text('Student Directory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search-students'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _students.length,
                itemBuilder: (context, i) {
                  final s = Map<String, dynamic>.from(_students[i]);
                  return Material(
                    color: Theme.of(context).colorScheme.surface,
                    child: ListTile(
                      title: Text('${s['user']?['first_name'] ?? ''} ${s['user']?['last_name'] ?? ''}'.trim().isEmpty ? (s['register_number'] ?? 'Student') : '${s['user']?['first_name'] ?? ''} ${s['user']?['last_name'] ?? ''}'.trim()),
                      subtitle: Text('${s['register_number'] ?? ''} • Block ${s['hostel_block'] ?? ''}'),
                      trailing: s['is_in_hostel'] == true ? const Icon(Icons.home, color: Colors.green) : const Icon(Icons.exit_to_app),
                      onTap: () => Navigator.pushNamed(context, '/student-profile-warden', arguments: s['id']),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
