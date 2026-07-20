import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/api_client.dart';

class OutpassDetailScreen extends StatefulWidget {
  const OutpassDetailScreen({super.key});

  @override
  State<OutpassDetailScreen> createState() => _OutpassDetailScreenState();
}

class _OutpassDetailScreenState extends State<OutpassDetailScreen> {
  Map<String, dynamic> _outpass = {};
  bool _loading = true;
  String? _outpassId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_outpassId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        _outpass = Map<String, dynamic>.from(args);
        _outpassId = _outpass['id']?.toString();
        _loading = false;
      } else if (args is String) {
        _outpassId = args;
      } else if (args is num) {
        _outpassId = args.toString();
      }
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    if (_outpassId == null) return;
    try {
      final res = await ApiClient.request('GET', '/outpass/$_outpassId/');
      if (mounted && res['success'] == true && res['data'] != null) {
        setState(() {
          _outpass = res['data'];
          _loading = false;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pass Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final status = _outpass['status'] ?? 'UNKNOWN';

    return Scaffold(
      appBar: AppBar(title: const Text('Pass Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status, style: AppTextStyles.badgeCaps),
            Text('ID: ${_outpass['id'] ?? ''}', style: AppTextStyles.bodySecondary),
            const SizedBox(height: 16),
            Text('Reason: ${_outpass['reason'] ?? ''}', style: AppTextStyles.bodyMain),
            Text('Destination: ${_outpass['destination'] ?? ''}', style: AppTextStyles.bodyMain),
            Text('Exit: ${_outpass['exit_date'] ?? ''} ${_outpass['exit_time'] ?? ''}', style: AppTextStyles.bodySecondary),
            Text('Return: ${_outpass['expected_return_date'] ?? ''} ${_outpass['expected_return_time'] ?? ''}', style: AppTextStyles.bodySecondary),
            if (_outpass['rejection_reason'] != null && _outpass['rejection_reason'].toString().isNotEmpty)
              Text('Rejection: ${_outpass['rejection_reason']}', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ),
      ),
    );
  }
}
