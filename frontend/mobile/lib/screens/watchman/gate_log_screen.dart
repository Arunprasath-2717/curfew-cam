import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/outpass_provider.dart';

class GateLogScreen extends StatefulWidget {
  const GateLogScreen({super.key});

  @override
  State<GateLogScreen> createState() => _GateLogScreenState();
}

class _GateLogScreenState extends State<GateLogScreen> {
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OutpassProvider>().refreshGateLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gate Log')),
      body: Consumer<OutpassProvider>(
        builder: (context, provider, _) {
          final allLogs = provider.gateLogs;
          final filtered = _filter == 'ALL'
              ? allLogs
              : allLogs.where((l) => l.scanType == _filter.replaceAll('S', '')).toList();

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: ['ALL', 'EXIT', 'RETURN'].map((f) {
                  return Padding(
                    padding: const EdgeInsets.all(4),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: _filter == f || (_filter == 'EXITS' && f == 'EXIT') || (_filter == 'RETURNS' && f == 'RETURN'),
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  );
                }).toList(),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.refreshGateLogs(),
                  child: filtered.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 100),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.sensor_door_outlined, size: 64, color: Colors.grey.withOpacity(0.5)),
                                  const SizedBox(height: 16),
                                  Text('No scans found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                                  const SizedBox(height: 8),
                                  const Text('No gate activity recorded yet.', style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final log = filtered[i];
                            return Material(
                              color: Theme.of(context).colorScheme.surface,
                              child: ListTile(
                                title: Text(log.studentName),
                                subtitle: Text('${log.scanType} • ${log.timestamp}'),
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
