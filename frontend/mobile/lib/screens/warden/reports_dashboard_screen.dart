import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/warden_service.dart';

class ReportsDashboardScreen extends StatefulWidget {
  const ReportsDashboardScreen({super.key});

  @override
  State<ReportsDashboardScreen> createState() => _ReportsDashboardScreenState();
}

class _ReportsDashboardScreenState extends State<ReportsDashboardScreen> {
  bool _loading = true;
  Map<String, dynamic> _report = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await WardenService.getReports('weekly');
    if (mounted) {
      setState(() {
        _loading = false;
        if (res['success'] == true) _report = Map<String, dynamic>.from(res['data'] ?? {});
      });
    }
  }

  int _count(String key) {
    final counts = _report['status_counts'];
    if (counts is Map) return (counts[key] ?? 0) as int;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final trend = _report['trend'] is List ? _report['trend'] as List : [];
    final approvalRate = _report['approval_rate'] ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weekly Summary', style: AppTextStyles.greeting),
                  Row(
                    children: [
                      Expanded(child: _box('Total', '${_report['total'] ?? 0}')),
                      const SizedBox(width: 12),
                      Expanded(child: _box('Pending', '${_count('PENDING')}')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Approval Rate: $approvalRate%', style: AppTextStyles.sectionHeader),
                  const SizedBox(height: 16),
                  if (trend.isNotEmpty)
                    SizedBox(
                      height: 160,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: trend.map((t) {
                          final m = Map<String, dynamic>.from(t);
                          final count = (m['count'] ?? 0) as int;
                          final max = trend.fold<int>(1, (a, b) {
                            final c = (Map<String, dynamic>.from(b)['count'] ?? 0) as int;
                            return c > a ? c : a;
                          });
                          return Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  height: 120 * (count / max),
                                  margin: const EdgeInsets.symmetric(horizontal: 2),
                                  color: Theme.of(context).primaryColor,
                                ),
                                Text(m['label']?.toString() ?? '', style: const TextStyle(fontSize: 9)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _box(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySecondary),
          Text(value, style: AppTextStyles.sectionHeader),
        ],
      ),
    );
  }
}
