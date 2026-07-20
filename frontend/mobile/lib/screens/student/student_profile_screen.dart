import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/bottom_nav_student.dart';
import '../../utils/string_utils.dart';

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _user;
  String? _avatarUrl;

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
          // Standardize name formatting
          _user!['first_name'] = _user!['name'] ?? _user!['first_name'] ?? 'Student';
          _user!['last_name'] = '';
          _user!['student_profile'] = {
            'register_number': _user!['rollNo'] ?? 'N/A',
            'room_number': _user!['room'] ?? 'N/A',
          };
          _avatarUrl = _user!['avatar'] as String?;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text('Student Profile', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            children: [
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else if (_user == null)
                Center(child: Text('Failed to load profile', style: AppTextStyles.bodyMain))
              else ...[
                // Header
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 4),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
                        ],
                      ),
                      child: AvatarWidget(
                        avatarUrl: _avatarUrl,
                        initials: safeInitial(_user?['first_name'], fallback: 'U'),
                        radius: 56,
                        backgroundColor: Theme.of(context).primaryColor,
                        textColor: Theme.of(context).scaffoldBackgroundColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('${_user!['first_name'] ?? ''} ${_user!['last_name'] ?? ''}', style: AppTextStyles.screenTitle.copyWith(color: Theme.of(context).primaryColor)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fingerprint, size: 18, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
                        const SizedBox(width: 4),
                        Text('Roll No: ${_user!['student_profile']?['register_number'] ?? 'N/A'}', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.meeting_room, size: 18, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
                        const SizedBox(width: 4),
                        Text('Room: ${_user!['student_profile']?['room_number'] ?? 'N/A'}', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                      ],
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/edit-profile'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Edit Profile'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Stats
              Row(
                children: [
                  Expanded(child: _buildStatBox(context, 'Total', '12', Theme.of(context).primaryColor)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatBox(context, 'Approved', '10', const Color(0xFF22C55E))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatBox(context, 'Rejected', '2', Theme.of(context).colorScheme.error)),
                ],
              ),
              const SizedBox(height: 24),
              
              // Info
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              border: Border.all(color: Theme.of(context).dividerColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.school, color: Theme.of(context).primaryColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('DEPARTMENT', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                                const SizedBox(height: 4),
                                Text('Computer Science & Engineering', style: AppTextStyles.cardTitle),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.calendar_today, color: Theme.of(context).scaffoldBackgroundColor),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('BATCH', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                                const SizedBox(height: 4),
                                Text('Class of 2024 (Semester 8)', style: AppTextStyles.cardTitle),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Settings
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    _buildSettingsRow(context, Icons.security, 'Security Settings', Theme.of(context).primaryColor, true),
                    _buildSettingsRow(context, Icons.support_agent, 'Help & Support', Theme.of(context).primaryColor, true),
                    Material(
                      color: Theme.of(context).colorScheme.surface,
                      child: ListTile(
                        leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                        title: Text('Log Out', style: AppTextStyles.bodyMain.copyWith(color: Theme.of(context).colorScheme.error)),
                        onTap: () async {
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
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ], // End of _user != null block
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavStudent(
        currentIndex: 3,
        onTap: (index) {
          if (index == 0) Navigator.of(context).popUntil((route) => route.isFirst);
          if (index == 1) Navigator.pushReplacementNamed(context, '/active-qr');
          if (index == 2) Navigator.pushReplacementNamed(context, '/history');
        },
      ),
    );
  }

  Widget _buildStatBox(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Text(label.toUpperCase(), style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.greeting.copyWith(fontSize: 24, color: color)),
        ],
      ),
    );
  }

  Widget _buildSettingsRow(BuildContext context, IconData icon, String title, Color iconColor, bool showDivider) {
    return Column(
      children: [
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: ListTile(
            leading: Icon(icon, color: iconColor),
            title: Text(title, style: AppTextStyles.bodyMain),
            trailing: Icon(Icons.chevron_right, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)),
            onTap: () {
              if (title == 'Security Settings') {
                Navigator.pushNamed(context, '/settings');
              } else if (title == 'Help & Support') {
                Navigator.pushNamed(context, '/help-faq');
              }
            },
          ),
        ),
        if (showDivider) Divider(color: Theme.of(context).dividerColor, height: 1),
      ],
    );
  }
}
