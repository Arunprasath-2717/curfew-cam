import 'package:flutter/material.dart';
import '../../providers/warden_service.dart';
import 'package:url_launcher/url_launcher.dart';

class LateReturnsAlertScreen extends StatefulWidget {
  const LateReturnsAlertScreen({super.key});

  @override
  State<LateReturnsAlertScreen> createState() => _LateReturnsAlertScreenState();
}

class _LateReturnsAlertScreenState extends State<LateReturnsAlertScreen> {
  bool _loading = true;
  List<dynamic> _late = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await WardenService.getLateStudents();
    if (mounted) {
      setState(() {
        _loading = false;
        if (res['success'] == true && res['data'] is List) {
          _late = res['data'] as List;
        }
      });
    }
  }
  
  Future<void> _callPhone(String phone) async {
    if (phone.isEmpty) return;
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Late Returns')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _late.isEmpty
                  ? ListView(children: const [Center(child: Text('No late students'))])
                  : ListView.builder(
                      itemCount: _late.length,
                      itemBuilder: (context, i) {
                        final item = Map<String, dynamic>.from(_late[i]);
                        final studentPhone = item['student_phone'] ?? '';
                        final guardianPhone = item['guardian_phone'] ?? '';
                        
                        return Material(
                          color: Theme.of(context).colorScheme.surface,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(item['student_name'] ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('Expected: ${item['expected_return_date'] ?? ''} ${item['expected_return_time'] ?? ''}'),
                                  trailing: const Icon(Icons.warning, color: Colors.red),
                                ),
                                if (studentPhone.isNotEmpty)
                                  InkWell(
                                    onTap: () => _callPhone(studentPhone),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.phone, size: 16, color: Colors.blue),
                                          const SizedBox(width: 8),
                                          Text('Student: $studentPhone', style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (guardianPhone.isNotEmpty)
                                  InkWell(
                                    onTap: () => _callPhone(guardianPhone),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.phone, size: 16, color: Colors.blue),
                                          const SizedBox(width: 8),
                                          Text('Guardian: $guardianPhone', style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                                        ],
                                      ),
                                    ),
                                  ),
                                const Divider(),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
