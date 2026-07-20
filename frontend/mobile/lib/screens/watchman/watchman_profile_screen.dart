import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/string_utils.dart';
import '../../widgets/avatar_widget.dart';

import 'package:provider/provider.dart';
import '../../providers/auth_service.dart';
import '../../providers/auth_provider.dart';

class WatchmanProfileScreen extends StatefulWidget {
  const WatchmanProfileScreen({super.key});

  @override
  State<WatchmanProfileScreen> createState() => _WatchmanProfileScreenState();
}

class _WatchmanProfileScreenState extends State<WatchmanProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final res = await AuthService.getMe();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true && res['data'] != null) {
          _user = res['data'];
          _avatarUrl = _user!['avatar'] as String?;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor, title: Row(children: [Icon(Icons.security, size: 20), SizedBox(width: 8), Text('GateControl', style: TextStyle(fontWeight: FontWeight.bold))])),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else if (_user == null)
                Center(child: Text('Failed to load profile', style: AppTextStyles.bodyMain))
              else ...[
                // Profile Hero
                Center(
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          AvatarWidget(
                            avatarUrl: _avatarUrl,
                            initials: safeInitial(_user?['first_name'], fallback: 'W'),
                            radius: 52,
                            backgroundColor: Theme.of(context).primaryColor,
                            textColor: Theme.of(context).scaffoldBackgroundColor,
                          ),
                          Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2)), child: Icon(Icons.edit, size: 16, color: Theme.of(context).scaffoldBackgroundColor)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('${_user!['first_name'] ?? ''} ${_user!['last_name'] ?? ''}', style: AppTextStyles.greeting.copyWith(color: Theme.of(context).primaryColor)),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.verified_user, size: 16, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)), SizedBox(width: 4), Text('Security Officer • ID #${_user!['watchman_profile']?['employee_id'] ?? 'N/A'}', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)))]),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Info Cards
                Row(
                  children: [
                    Expanded(child: _buildInfoCard(context, 'Gate Assignment', _user!['watchman_profile']?['gate_assigned'] ?? 'Main Gate', Icons.door_front_door, Theme.of(context).primaryColor)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildInfoCard(context, 'Shift Timing', _user!['watchman_profile']?['shift'] ?? 'Night Shift', Icons.dark_mode, Theme.of(context).colorScheme.secondary)),
                  ],
                ),
              ],
              const SizedBox(height: 32),
              // Settings Links
              Align(alignment: Alignment.centerLeft, child: Text('Account Settings', style: AppTextStyles.sectionHeader.copyWith(color: Theme.of(context).primaryColor))),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Column(
                  children: [
                    _buildSettingsLink(context, 'Change Password', Icons.lock_reset),
                    Divider(height: 1),
                    _buildSettingsLink(context, 'Alert Preferences', Icons.notifications_active),
                    Divider(height: 1),
                    _buildSettingsLink(context, 'Support & Guidelines', Icons.help_center),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Logout
              ElevatedButton.icon(onPressed: () async {
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

                final navigator = Navigator.of(context);
                final authProvider = context.read<AuthProvider>();
                await authProvider.logout();
                if (!mounted) return;
                navigator.pushNamedAndRemoveUntil('/login', (route) => false);
              }, icon: Icon(Icons.logout), label: Text('Log Out'), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48), backgroundColor: Theme.of(context).colorScheme.error, foregroundColor: Theme.of(context).scaffoldBackgroundColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              Text('App Version 2.4.1 (Stable Build)', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey).withValues(alpha: 0.6))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.sectionHeader.copyWith(color: Theme.of(context).primaryColor)),
        ],
      ),
    );
  }

  Widget _buildSettingsLink(BuildContext context, String title, IconData icon) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: ListTile(
        leading: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Theme.of(context).primaryColor)),
        title: Text(title, style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor)),
        trailing: Icon(Icons.chevron_right, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
        onTap: () {},
      ),
    );
  }
}
