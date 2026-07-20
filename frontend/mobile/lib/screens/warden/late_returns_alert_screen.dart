import 'package:flutter/material.dart';
import '../../providers/warden_service.dart';

class LateReturnsAlertScreen extends StatefulWidget {
  const LateReturnsAlertScreen({super.key});

  @override
  State<LateReturnsAlertScreen> createState() => _LateReturnsAlertScreenState();
}

class _LateReturnsAlertScreenState extends State<LateReturnsAlertScreen> {
  bool _loading = true;
  List<dynamic> _late = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await WardenService.getLateStudents();
    if (mounted) {
      setState(() {
        _loading = false;
        if (res['success'] == true && res['data'] is List) {
          _late = res['data'] as List;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Late Returns')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _late.isEmpty
                  ? ListView(children: const [Center(child: Text('No late students'))])
                  : ListView.builder(
                      itemCount: _late.length,
                      itemBuilder: (context, i) {
                        final item = Map<String, dynamic>.from(_late[i]);
                        return Material(
                          color: Theme.of(context).colorScheme.surface,
                          child: ListTile(
                            title: Text(item['student_name'] ?? 'Student'),
                            subtitle: Text('Expected: ${item['expected_return_date'] ?? ''} ${item['expected_return_time'] ?? ''}'),
                            trailing: const Icon(Icons.warning, color: Colors.red),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
