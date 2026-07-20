import 'package:flutter/material.dart';
import '../../providers/watchman_service.dart';

class ShiftSummaryScreen extends StatefulWidget {
  const ShiftSummaryScreen({super.key});

  @override
  State<ShiftSummaryScreen> createState() => _ShiftSummaryScreenState();
}

class _ShiftSummaryScreenState extends State<ShiftSummaryScreen> {
  bool _loading = true;
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await WatchmanService.getShiftSummary();
    if (mounted) {
      setState(() {
        _loading = false;
        if (res['success'] == true) _summary = Map<String, dynamic>.from(res['data'] ?? {});
      });
    }
  }

  Future<void> _startShift() async {
    await WatchmanService.startShift();
    _load();
  }

  Future<void> _endShift() async {
    await WatchmanService.endShift();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final onDuty = _summary['on_duty'] == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Shift Summary')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(onDuty ? 'On Duty' : 'Off Duty', style: Theme.of(context).textTheme.headlineSmall),
                  if (onDuty) Text('Started: ${_summary['shift_start'] ?? ''}'),
                  if (onDuty) Text('Gate: ${_summary['gate'] ?? ''}'),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _box('Total Scans', '${_summary['total_scans'] ?? 0}'),
                      const SizedBox(width: 12),
                      _box('Exits', '${_summary['exits'] ?? 0}'),
                      const SizedBox(width: 12),
                      _box('Returns', '${_summary['returns'] ?? 0}'),
                    ],
                  ),
                  const Spacer(),
                  if (onDuty)
                    ElevatedButton(onPressed: _endShift, child: const Text('End Shift'))
                  else
                    ElevatedButton(onPressed: _startShift, child: const Text('Start Shift')),
                ],
              ),
            ),
    );
  }

  Widget _box(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [Text(label), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))],
        ),
      ),
    );
  }
}
