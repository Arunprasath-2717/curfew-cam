import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/change_password_dialog.dart';
import '../../providers/outpass_provider.dart';

class WatchmanSettingsScreen extends StatefulWidget {
  const WatchmanSettingsScreen({super.key});

  @override
  State<WatchmanSettingsScreen> createState() => _WatchmanSettingsScreenState();
}

class _WatchmanSettingsScreenState extends State<WatchmanSettingsScreen> {
  bool _soundAlerts = true;
  bool _vibrateOnScan = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundAlerts = prefs.getBool('watchman_sound_alerts') ?? true;
      _vibrateOnScan = prefs.getBool('watchman_vibrate_scan') ?? true;
    });
  }

  Future<void> _togglePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _handleLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor, title: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Text('General', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
            const SizedBox(height: 8),
            Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              elevation: 0,
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _soundAlerts, 
                      onChanged: (v) {
                        setState(() => _soundAlerts = v);
                        _togglePref('watchman_sound_alerts', v);
                      }, 
                      title: Text('Sound Alerts'), activeColor: Theme.of(context).primaryColor
                    ),
                    Divider(height: 1),
                    SwitchListTile(
                      value: _vibrateOnScan, 
                      onChanged: (v) {
                        setState(() => _vibrateOnScan = v);
                        _togglePref('watchman_vibrate_scan', v);
                      }, 
                      title: Text('Vibrate on Scan'), activeColor: Theme.of(context).primaryColor
                    ),
                    Divider(height: 1),
                    SwitchListTile(
                      value: context.watch<ThemeProvider>().themeMode == ThemeMode.dark, 
                      onChanged: (v) {
                        context.read<ThemeProvider>().setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
                      }, 
                      title: Text('Dark Mode'), activeColor: Theme.of(context).primaryColor
                    ),
                    Divider(height: 1),
                    ListTile(
                      title: Text('Change Password'),
                      trailing: Icon(Icons.lock_reset),
                      onTap: () => showChangePasswordDialog(context),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Device & Sync', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
            const SizedBox(height: 8),
            Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(16),
              elevation: 0,
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Column(
                  children: [
                    ListTile(
                      title: Text('Force Sync Log'),
                      trailing: Icon(Icons.sync),
                      onTap: () async {
                        await context.read<OutpassProvider>().refreshGateLogs();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gate logs synced')),
                          );
                        }
                      },
                    ),
                    Divider(height: 1),
                    ListTile(title: Text('Clear Cache'), trailing: Icon(Icons.delete_outline), onTap: () {}),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _handleLogout,
              icon: Icon(Icons.logout),
              label: Text('Log Out'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

