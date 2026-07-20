import 'package:flutter/material.dart';
import '../../providers/warden_service.dart';
import '../../widgets/status_chip.dart';
import '../../theme/app_text_styles.dart';

class ApprovedHistoryWardenScreen extends StatefulWidget {
  const ApprovedHistoryWardenScreen({super.key});

  @override
  State<ApprovedHistoryWardenScreen> createState() => _ApprovedHistoryWardenScreenState();
}

class _ApprovedHistoryWardenScreenState extends State<ApprovedHistoryWardenScreen> {
  bool _loading = true;
  List<dynamic> _logs = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await WardenService.getHistory();
    if (mounted) {
      setState(() {
        _loading = false;
        if (res['success'] == true && res['data'] is List) {
          _logs = res['data'] as List;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pass History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _logs.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 100),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_rounded, size: 64, color: Colors.grey.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text('No history found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                              const SizedBox(height: 8),
                              const Text('Past approved/rejected requests will appear here.', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _logs.length,
                      itemBuilder: (context, i) {
                        final log = Map<String, dynamic>.from(_logs[i]);
                        final status = (log['status'] ?? 'UNKNOWN').toString();
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            title: Text(log['student_name'] ?? 'Student', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold)),
                            subtitle: Text('${log['destination'] ?? 'No destination'} • ${log['exit_date'] ?? ''}', style: AppTextStyles.bodySecondary),
                            trailing: StatusChip(status: status),
                            onTap: () => Navigator.pushNamed(context, '/request-detail', arguments: log['id']),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
