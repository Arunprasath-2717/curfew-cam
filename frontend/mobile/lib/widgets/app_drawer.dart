import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_text_styles.dart';
import '../widgets/avatar_widget.dart';
import '../utils/string_utils.dart';

class AppDrawer extends StatefulWidget {
  final String currentRole; // 'student', 'warden', 'watchman', 'admin_warden'

  const AppDrawer({super.key, required this.currentRole});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Map<String, dynamic>? _user;
  String? _avatarUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('ag_user');
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (userStr != null) {
          _user = jsonDecode(userStr);
          _user!['first_name'] = _user!['name'] ?? _user!['first_name'] ?? 'User';
          _user!['last_name'] = _user!['last_name'] ?? '';
          _avatarUrl = _user!['avatar'] as String?;
        }
      });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
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
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    navigator.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black87;

    return Drawer(
      backgroundColor: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.primaryColor, width: 2),
                          ),
                          child: AvatarWidget(
                            avatarUrl: _avatarUrl,
                            initials: safeInitial(_user?['email'], fallback: 'U'),
                            radius: 32,
                            backgroundColor: theme.primaryColor,
                            textColor: theme.scaffoldBackgroundColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_user?['first_name'] ?? ''} ${_user?['last_name'] ?? ''}'.trim(),
                                style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _user?['email'] ?? '',
                                style: AppTextStyles.bodySecondary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            const Divider(height: 1),

            // Role-specific quick links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _buildRoleItems(context),
              ),
            ),

            const Divider(height: 1),
            // Bottom fixed items
            ListTile(
              leading: Icon(Icons.logout, color: theme.colorScheme.error),
              title: Text('Log Out', style: AppTextStyles.bodyMain.copyWith(color: theme.colorScheme.error)),
              onTap: () => _handleLogout(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRoleItems(BuildContext context) {
    List<Widget> items = [];

    // Full Profile Link (Common for all but routes differ slightly)
    items.add(
      ListTile(
        leading: const Icon(Icons.person_outline),
        title: const Text('View Full Profile'),
        onTap: () {
          Navigator.pop(context); // Close drawer
          if (widget.currentRole == 'student') {
            Navigator.pushNamed(context, '/student-profile');
          } else if (widget.currentRole == 'warden' || widget.currentRole == 'admin_warden') {
            Navigator.pushNamed(context, '/warden-profile');
          } else if (widget.currentRole == 'watchman') {
            Navigator.pushNamed(context, '/watchman-profile');
          }
        },
      ),
    );

    items.add(const SizedBox(height: 16));
    items.add(
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text('SETTINGS', style: AppTextStyles.badgeCaps),
      ),
    );

    // Settings links based on role
    if (widget.currentRole == 'student') {
      items.add(_buildNavItem(context, Icons.security, 'Security Settings', '/settings'));
      items.add(_buildNavItem(context, Icons.help_outline, 'Help & FAQ', '/help-faq'));
    } else if (widget.currentRole == 'warden' || widget.currentRole == 'admin_warden') {
      if (widget.currentRole == 'admin_warden') {
        items.add(_buildNavItem(context, Icons.admin_panel_settings, 'Manage Wardens', '/manage-wardens'));
      }
      items.add(_buildNavItem(context, Icons.settings, 'Warden Settings', '/warden-settings'));
    } else if (widget.currentRole == 'watchman') {
      items.add(_buildNavItem(context, Icons.settings, 'Settings', '/watchman-settings'));
      items.add(_buildNavItem(context, Icons.help_outline, 'Help & Support', '/help-support-watchman'));
    }

    return items;
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title, String routeName) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: AppTextStyles.bodyMain),
      onTap: () {
        Navigator.pop(context); // Close drawer first
        Navigator.pushNamed(context, routeName);
      },
    );
  }
}
