import 'package:flutter/material.dart';
import '../../providers/warden_service.dart';

class ApproveConfirmationScreen extends StatefulWidget {
  const ApproveConfirmationScreen({super.key});

  @override
  State<ApproveConfirmationScreen> createState() => _ApproveConfirmationScreenState();
}

class _ApproveConfirmationScreenState extends State<ApproveConfirmationScreen> {
  bool _loading = false;

  Future<void> _approve() async {
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null) return;
    setState(() => _loading = true);
    final res = await WardenService.approveOutpass(id);
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
      appBar: AppBar(title: const Text('Approve Request')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: Color(0xFF22C55E)),
            const SizedBox(height: 16),
            const Text('Confirm approval of this outpass request?'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _approve,
              child: _loading ? const CircularProgressIndicator() : const Text('Approve'),
            ),
          ],
        ),
      ),
    );
  }
}
