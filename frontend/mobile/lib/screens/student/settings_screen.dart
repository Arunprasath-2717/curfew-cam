import 'package:flutter/material.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/change_password_dialog.dart' show showChangePasswordDialog;
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBarWidget(title: 'Settings', showBackButton: false),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Appearance ──
          _SectionTitle(title: 'Appearance'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.light_mode_rounded,
                iconColor: AppColors.amber,
                title: 'Appearance',
                trailing: Text('Light Mode (Default)', style: AppTextStyles.bodySecondary.copyWith(fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Security ──
          _SectionTitle(title: 'Security'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.lock_rounded,
                iconColor: AppColors.navy,
                title: 'Change Password',
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                onTap: () => showChangePasswordDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Notifications ──
          _SectionTitle(title: 'Notifications'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.notifications_active_rounded,
                iconColor: AppColors.amber,
                title: 'Push Notifications',
                trailing: Switch.adaptive(
                  value: true,
                  activeTrackColor: AppColors.success,
                  onChanged: (_) {},
                ),
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.email_rounded,
                iconColor: AppColors.accentBlue,
                title: 'Email Alerts',
                trailing: Switch.adaptive(
                  value: false,
                  activeTrackColor: AppColors.success,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── About ──
          _SectionTitle(title: 'About'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.info_rounded,
                iconColor: AppColors.accentTeal,
                title: 'App Version',
                trailing: Text('1.0.0', style: AppTextStyles.bodySecondary),
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.description_rounded,
                iconColor: AppColors.textSecondary,
                title: 'Terms & Privacy',
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Reusable sub-widgets ──

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(title, style: AppTextStyles.badgeCaps.copyWith(
        color: AppColors.textSecondary,
        letterSpacing: 1.2,
      )),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(children: children),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: AppTextStyles.bodyMain),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
