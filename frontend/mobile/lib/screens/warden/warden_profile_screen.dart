import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/string_utils.dart';
import '../../widgets/avatar_widget.dart';

import 'package:provider/provider.dart';
import '../../providers/auth_service.dart';
import '../../providers/auth_provider.dart';

class WardenProfileScreen extends StatefulWidget {
  const WardenProfileScreen({super.key});

  @override
  State<WardenProfileScreen> createState() => _WardenProfileScreenState();
}

class _WardenProfileScreenState extends State<WardenProfileScreen> {
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
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('Profile', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(icon: Icon(Icons.menu), onPressed: () {}),
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
              const SizedBox(height: 24),
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else if (_user == null)
                Center(child: Text('Failed to load profile', style: AppTextStyles.bodyMain))
              else ...[
                // Hero Profile Section
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
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2)),
                      child: Icon(Icons.edit, color: Theme.of(context).scaffoldBackgroundColor, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('${_user!['first_name'] ?? ''} ${_user!['last_name'] ?? ''}', style: AppTextStyles.screenTitle),
                Text('Hostel Administrator', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                const SizedBox(height: 32),
                
                // Warden Details Card
                Container(
                  decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(16)), border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor))),
                        width: double.infinity,
                        child: Text('Official Information', style: AppTextStyles.sectionHeader),
                      ),
                      _buildInfoRow(context, 'Name', '${_user!['first_name'] ?? ''} ${_user!['last_name'] ?? ''}'),
                      Divider(height: 1, color: Theme.of(context).dividerColor),
                      _buildInfoRow(context, 'Hostel Name', _user!['warden_profile']?['hostel_name'] ?? 'N/A'),
                      Divider(height: 1, color: Theme.of(context).dividerColor),
                      _buildInfoRow(context, 'Block Assignment', _user!['warden_profile']?['hostel_name'] ?? 'N/A'),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              
              // Navigation Links
              _buildNavButton(context, Icons.account_circle, 'Account Settings'),
              const SizedBox(height: 12),
              _buildNavButton(context, Icons.lock, 'Change Password'),
              const SizedBox(height: 32),
              
              // Log Out Button
              OutlinedButton.icon(
                onPressed: () async {
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
                },
                icon: Icon(Icons.logout),
                label: Text('Log Out'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(color: Theme.of(context).colorScheme.error),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
          Text(value, style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, IconData icon, String label) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor)),
        child: Row(
          children: [
            Icon(icon, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: AppTextStyles.bodyMain)),
            Icon(Icons.chevron_right, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
          ],
        ),
      ),
    );
  }
}
