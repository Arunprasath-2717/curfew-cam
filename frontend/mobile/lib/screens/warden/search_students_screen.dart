import 'package:flutter/material.dart';
import '../../providers/warden_service.dart';

class SearchStudentsScreen extends StatefulWidget {
  const SearchStudentsScreen({super.key});

  @override
  State<SearchStudentsScreen> createState() => _SearchStudentsScreenState();
}

class _SearchStudentsScreenState extends State<SearchStudentsScreen> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  List<dynamic> _results = [];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final res = await WardenService.searchStudents(_ctrl.text.trim());
    if (mounted) {
      setState(() {
        _loading = false;
        _results = res['success'] == true && res['data'] is List ? res['data'] as List : [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Students')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: const InputDecoration(hintText: 'Name or register number'),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                IconButton(onPressed: _search, icon: const Icon(Icons.search)),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, i) {
                final s = Map<String, dynamic>.from(_results[i]);
                return Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: ListTile(
                    title: Text('${s['user']?['first_name'] ?? ''} ${s['user']?['last_name'] ?? ''}'.trim().isEmpty ? (s['register_number'] ?? 'Student') : '${s['user']?['first_name'] ?? ''} ${s['user']?['last_name'] ?? ''}'.trim()),
                    subtitle: Text('${s['register_number'] ?? ''} • ${s['hostel_block'] ?? ''}'),
                    onTap: () => Navigator.pushNamed(context, '/student-profile-warden', arguments: s['id']),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
