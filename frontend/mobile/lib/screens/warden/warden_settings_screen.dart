import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/change_password_dialog.dart';

class WardenSettingsScreen extends StatefulWidget {
  const WardenSettingsScreen({super.key});

  @override
  State<WardenSettingsScreen> createState() => _WardenSettingsScreenState();
}

class _WardenSettingsScreenState extends State<WardenSettingsScreen> {
  bool _pushNotifications = true;
  final TextEditingController _cameraUrlController = TextEditingController();

  @override
  void dispose() {
    _cameraUrlController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('warden_push_notifications') ?? true;
      _cameraUrlController.text = prefs.getString('gate_camera_url') ?? '';
    });
  }

  Future<void> _togglePushNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('warden_push_notifications', value);
    setState(() => _pushNotifications = value);
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

  Future<void> _saveCameraUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gate_camera_url', value);
  }

  void _showCameraDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Gate Camera Configuration'),
          content: TextField(
            controller: _cameraUrlController,
            decoration: InputDecoration(
              labelText: 'MJPEG Stream URL',
              hintText: 'http://192.168.1.100:81/stream',
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                _saveCameraUrl(_cameraUrlController.text);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('CurfewCam', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Header Removed
              const SizedBox(height: 16),
              
              // Settings Container
              Container(
                decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.vertical(top: Radius.circular(24), bottom: Radius.circular(12)), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Column(
                  children: [
                    _buildSwitchItem(context, Icons.notifications_active, 'Push Notifications', 'Alerts for pending requests', _pushNotifications, _togglePushNotifications),
                    _buildNavItem(context, Icons.light_mode, 'Appearance', 'Light Mode (Default)'),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _buildNavItem(context, Icons.apartment, 'Hostel Details', 'Block A, Rooms 101-500'),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _buildNavItem(context, Icons.schedule, 'Working Hours', '08:00 AM - 10:00 PM'),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _buildNavItem(context, Icons.lock_reset, 'Change Password', 'Last changed 2 months ago', onTap: () => showChangePasswordDialog(context)),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _buildNavItem(context, Icons.videocam, 'Camera Setup', 'Configure gate MJPEG stream', onTap: _showCameraDialog),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    _buildNavItem(context, Icons.info, 'About App', 'Version 2.4.0 (Build 102)'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Log Out Button
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
              
              const SizedBox(height: 48),
              // Aesthetic Branding Element
              Opacity(
                opacity: 0.4,
                child: Column(
                  children: [
                    Container(width: 48, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(height: 16),
                    Text('POWERED BY CURFEWCAM SECURITY', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey), letterSpacing: 2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem(BuildContext context, IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Theme.of(context).primaryColor)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.cardTitle.copyWith(color: Theme.of(context).textTheme.titleMedium?.color)),
                Text(subtitle, style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: Theme.of(context).primaryColor),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: Theme.of(context).primaryColor)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.cardTitle.copyWith(color: Theme.of(context).textTheme.titleMedium?.color)),
                  Text(subtitle, style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
          ],
        ),
      ),
    );
  }
}

