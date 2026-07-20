import 'package:flutter/material.dart';
import '../../providers/warden_service.dart';

class PassViolationRecordScreen extends StatefulWidget {
  const PassViolationRecordScreen({super.key});

  @override
  State<PassViolationRecordScreen> createState() => _PassViolationRecordScreenState();
}

class _PassViolationRecordScreenState extends State<PassViolationRecordScreen> {
  bool _loading = true;
  List<dynamic> _violations = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    final res = await WardenService.getStudentViolations(id);
    if (mounted) {
      setState(() {
        _loading = false;
        if (res['success'] == true && res['data'] is List) {
          _violations = res['data'] as List;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Violation Records')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _violations.isEmpty
              ? const Center(child: Text('No violations'))
              : ListView.builder(
                  itemCount: _violations.length,
                  itemBuilder: (context, i) {
                    final v = Map<String, dynamic>.from(_violations[i]);
                    return ListTile(
                      title: Text(v['status'] ?? 'Violation'),
                      subtitle: Text(v['rejection_reason'] ?? v['reason'] ?? ''),
                      trailing: v['is_late'] == true ? const Icon(Icons.warning, color: Colors.red) : null,
                    );
                  },
                ),
    );
  }
}
