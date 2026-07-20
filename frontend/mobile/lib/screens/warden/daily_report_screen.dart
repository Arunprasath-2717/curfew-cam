import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/warden_service.dart';

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  bool _loading = true;
  Map<String, dynamic> _report = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await WardenService.getReports('daily');
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
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Report')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Report', style: AppTextStyles.screenTitle),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _box('Total', '${_report['total'] ?? 0}'),
                      _box('Approved', '${_count('APPROVED') + _count('ACTIVE') + _count('RETURNED')}'),
                      _box('Rejected', '${_count('REJECTED')}'),
                      _box('Late', '${_report['late_count'] ?? 0}'),
                    ],
                  ),
                  const SizedBox(height: 24),
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
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  color: Theme.of(context).primaryColor,
                                ),
                                Text(m['label']?.toString() ?? '', style: const TextStyle(fontSize: 10)),
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
