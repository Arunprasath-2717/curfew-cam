import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/warden_service.dart';

class AnalyticsOverviewScreen extends StatefulWidget {
  const AnalyticsOverviewScreen({super.key});

  @override
  State<AnalyticsOverviewScreen> createState() => _AnalyticsOverviewScreenState();
}

class _AnalyticsOverviewScreenState extends State<AnalyticsOverviewScreen> {
  bool _loading = true;
  Map<String, dynamic> _report = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await WardenService.getReports('trend');
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
    final total = (_report['total'] ?? 1) as int;
    final approved = _count('APPROVED') + _count('ACTIVE') + _count('RETURNED');
    final rejected = _count('REJECTED');
    final pending = _count('PENDING');
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analytics Overview', style: AppTextStyles.greeting),
                  Text('Approval rate: ${_report['approval_rate'] ?? 0}%', style: AppTextStyles.bodyMain),
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
                                  color: Theme.of(context).primaryColor.withOpacity(0.8),
                                ),
                                Text(m['label']?.toString() ?? ''),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _statusRow('Approved', approved, total),
                  _statusRow('Rejected', rejected, total),
                  _statusRow('Pending', pending, total),
                ],
              ),
            ),
    );
  }

  Widget _statusRow(String label, int count, int total) {
    final pct = total > 0 ? (count / total * 100).round() : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text('$pct% ($count)')],
      ),
    );
  }
}
