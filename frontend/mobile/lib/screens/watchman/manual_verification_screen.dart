import 'package:flutter/material.dart';
import '../../providers/watchman_service.dart';

class ManualVerificationScreen extends StatefulWidget {
  const ManualVerificationScreen({super.key});

  @override
  State<ManualVerificationScreen> createState() => _ManualVerificationScreenState();
}

class _ManualVerificationScreenState extends State<ManualVerificationScreen> {
  final _regCtrl = TextEditingController();
  bool _exitMode = true;
  bool _loading = false;
  Map<String, dynamic>? _lastResult;

  @override
  void dispose() {
    _regCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_regCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final res = await WatchmanService.manualVerify(
      _regCtrl.text.trim(),
      _exitMode ? 'EXIT' : 'RETURN',
    );
    if (mounted) {
      setState(() {
        _loading = false;
        _lastResult = res;
      });
      if (res['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Verified')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Failed')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manual Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('EXIT'),
                    selected: _exitMode,
                    onSelected: (_) => setState(() => _exitMode = true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('RETURN'),
                    selected: !_exitMode,
                    onSelected: (_) => setState(() => _exitMode = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _regCtrl,
              decoration: const InputDecoration(labelText: 'Register Number', hintText: 'e.g. 20ME088'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _verify,
              child: _loading ? const CircularProgressIndicator() : Text(_exitMode ? 'Mark Exit' : 'Mark Return'),
            ),
            if (_lastResult?['success'] == true) ...[
              const SizedBox(height: 24),
              Text('Verified: ${_lastResult!['data']?['student_name'] ?? ''}'),
            ],
          ],
        ),
      ),
    );
  }
}
