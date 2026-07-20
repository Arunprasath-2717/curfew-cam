import 'package:flutter/material.dart';
import '../../providers/warden_service.dart';

class BulkApproveScreen extends StatefulWidget {
  const BulkApproveScreen({super.key});

  @override
  State<BulkApproveScreen> createState() => _BulkApproveScreenState();
}

class _BulkApproveScreenState extends State<BulkApproveScreen> {
  bool _loading = true;
  bool _submitting = false;
  List<dynamic> _requests = [];
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await WardenService.getPendingRequests();
    if (mounted) {
      setState(() {
        _loading = false;
        if (res['success'] == true && res['data'] is List) {
          _requests = res['data'] as List;
        }
      });
    }
  }

  Future<void> _bulkApprove() async {
    if (_selected.isEmpty) return;
    setState(() => _submitting = true);
    final res = await WardenService.bulkApprove(_selected.toList());
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message'] ?? 'Done')),
    );
    if (res['success'] == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Approve')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _requests.length,
                    itemBuilder: (context, i) {
                      final item = Map<String, dynamic>.from(_requests[i]);
                      final id = item['id'].toString();
                      return CheckboxListTile(
                        value: _selected.contains(id),
                        onChanged: (v) => setState(() {
                          if (v == true) {
                            _selected.add(id);
                          } else {
                            _selected.remove(id);
                          }
                        }),
                        title: Text(item['student_name'] ?? 'Student'),
                        subtitle: Text(item['destination'] ?? ''),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _submitting || _selected.isEmpty ? null : _bulkApprove,
                    child: Text(_submitting ? 'Approving...' : 'Approve Selected (${_selected.length})'),
                  ),
                ),
              ],
            ),
    );
  }
}
