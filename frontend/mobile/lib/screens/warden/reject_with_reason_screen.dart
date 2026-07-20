import 'package:flutter/material.dart';
import '../../providers/warden_service.dart';

class RejectWithReasonScreen extends StatefulWidget {
  const RejectWithReasonScreen({super.key});

  @override
  State<RejectWithReasonScreen> createState() => _RejectWithReasonScreenState();
}

class _RejectWithReasonScreenState extends State<RejectWithReasonScreen> {
  final _reasonCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null || _reasonCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final res = await WardenService.rejectOutpass(id, _reasonCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['success'] == true) {
      Navigator.popUntil(context, (r) => r.settings.name == '/warden-dashboard' || r.isFirst);
      Navigator.pushReplacementNamed(context, '/warden-dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reject Request')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _reasonCtrl,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Rejection reason'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading ? const CircularProgressIndicator() : const Text('Confirm Reject'),
            ),
          ],
        ),
      ),
    );
  }
}
