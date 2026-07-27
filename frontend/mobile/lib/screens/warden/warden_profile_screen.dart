import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Warden Profile', style: AppTextStyles.screenTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_user == null)
                Center(child: Text('Failed to load profile', style: AppTextStyles.bodyMain))
              else ...[
                // Hero Profile Section
                AvatarWidget(
                  avatarUrl: _avatarUrl,
                  initials: safeInitial(_user?['first_name'], fallback: 'W'),
                  radius: 56,
                  backgroundColor: AppColors.navy,
                  textColor: Colors.white,
                ),
                const SizedBox(height: 16),
                Text(
                  '${_user!['first_name'] ?? ''} ${_user!['last_name'] ?? ''}'.trim(),
                  style: AppTextStyles.screenTitle.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 4),
                Text(
                  _user!['email'] ?? '',
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: 32),
                
                // Details Card
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('Official Information', style: AppTextStyles.sectionHeader.copyWith(color: AppColors.navy)),
                      ),
                      const Divider(height: 1),
                      _buildInfoRow(context, Icons.badge_outlined, 'Employee ID', _user!['warden_profile']?['employee_id'] ?? 'N/A'),
                      const Divider(height: 1),
                      _buildInfoRow(context, Icons.apartment_outlined, 'Hostel Assignment', _user!['warden_profile']?['hostel_name'] ?? 'All Hostels'),
                      const Divider(height: 1),
                      _buildInfoRow(context, Icons.calendar_today_outlined, 'Year Assignment', _user!['warden_profile']?['assigned_year']?.toString() ?? 'All Years'),
                      const Divider(height: 1),
                      _buildInfoRow(context, Icons.phone_outlined, 'Phone', _user!['phone_number'] ?? 'N/A'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Actions
                _buildActionCard(
                  context, 
                  icon: Icons.logout_rounded, 
                  title: 'Log Out',
                  color: AppColors.error,
                  onTap: () async {
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Log Out'),
                        content: const Text('Are you sure you want to log out?'),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                ),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.bodySecondary.copyWith(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'N/A' : value,
                  style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              title,
              style: AppTextStyles.bodyMain.copyWith(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
