import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/outpass_provider.dart';
import '../../providers/watchman_service.dart';
import '../../widgets/bottom_nav_watchman.dart';
import '../../widgets/app_drawer.dart';

class WatchmanDashboardScreen extends StatefulWidget {
  const WatchmanDashboardScreen({super.key});

  @override
  State<WatchmanDashboardScreen> createState() => _WatchmanDashboardScreenState();
}

class _WatchmanDashboardScreenState extends State<WatchmanDashboardScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await context.read<OutpassProvider>().refreshGateLogs();
    final res = await WatchmanService.getDashboard();
    if (mounted) {
      setState(() {
        _loading = false;
        if (res['success'] == true) _stats = Map<String, dynamic>.from(res['data'] ?? {});
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, Officer';
    if (hour < 17) return 'Good afternoon, Officer';
    return 'Good evening, Officer';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: const AppDrawer(currentRole: 'watchman'),
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: const Row(children: [Icon(Icons.security, size: 20), SizedBox(width: 8), Text('CurfewCam', style: TextStyle(fontWeight: FontWeight.bold))]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getGreeting(), style: AppTextStyles.bodySecondary),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _stat('EXITS', '${_stats['exits_today'] ?? 0}'),
                        const SizedBox(width: 8),
                        _stat('RETURNS', '${_stats['returns_today'] ?? 0}'),
                        const SizedBox(width: 8),
                        _stat('ACTIVE', '${_stats['active_outpasses'] ?? 0}'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/qr-scanner'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.qr_code_scanner, size: 64, color: Theme.of(context).scaffoldBackgroundColor),
                            const SizedBox(height: 8),
                            Text('Scan QR Code', style: AppTextStyles.sectionHeader.copyWith(color: Theme.of(context).scaffoldBackgroundColor)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _navBtn('Manual Entry', '/manual-verification'),
                        _navBtn('Gate Log', '/gate-log'),
                        _navBtn('Active Passes', '/active-passes'),
                        _navBtn('Overdue', '/overdue-students'),
                        _navBtn('Shift Summary', '/shift-summary'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavWatchman(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, '/qr-scanner');
          if (index == 2) Navigator.pushNamed(context, '/gate-log');
        },
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: AppTextStyles.badgeCaps),
            Text(value, style: AppTextStyles.sectionHeader),
          ],
        ),
      ),
    );
  }

  Widget _navBtn(String label, String route) {
    return OutlinedButton(
      onPressed: () => Navigator.pushNamed(context, route),
      child: Text(label),
    );
  }
}
