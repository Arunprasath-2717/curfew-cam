import 'package:flutter/material.dart';
import '../../providers/watchman_service.dart';

class ActivePassesWatchmanScreen extends StatefulWidget {
  const ActivePassesWatchmanScreen({super.key});

  @override
  State<ActivePassesWatchmanScreen> createState() => _ActivePassesWatchmanScreenState();
}

class _ActivePassesWatchmanScreenState extends State<ActivePassesWatchmanScreen> {
  bool _loading = true;
  List<dynamic> _passes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await WatchmanService.getActivePasses();
    if (mounted) {
      setState(() {
        _loading = false;
        if (res['success'] == true && res['data'] is List) {
          _passes = res['data'] as List;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Passes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _passes.length,
                itemBuilder: (context, i) {
                  final p = Map<String, dynamic>.from(_passes[i]);
                  return Material(
                    color: Theme.of(context).colorScheme.surface,
                    child: ListTile(
                      title: Text(p['student_name'] ?? 'Student'),
                      subtitle: Text('${p['student_register'] ?? ''} • ${p['destination'] ?? ''}'),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
