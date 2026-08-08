import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bottom_nav_warden.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/warden_service.dart';
import '../../providers/auth_service.dart';
import '../../providers/outpass_provider.dart';
import '../../utils/string_utils.dart';
import '../../services/announcement_service.dart';

class WardenDashboardScreen extends StatefulWidget {
  const WardenDashboardScreen({super.key});

  @override
  State<WardenDashboardScreen> createState() => _WardenDashboardScreenState();
}

class _WardenDashboardScreenState extends State<WardenDashboardScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _pending = [];
  String _wardenName = 'Warden';
  String _hostelName = 'Hostel';
  String _userRole = 'warden';
  int _unreadCount = 0;
  List<dynamic> _announcements = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final meRes = await AuthService.getMe();
      if (meRes['success'] == true && meRes['data'] != null) {
        _wardenName = meRes['data']['full_name'] ?? meRes['data']['first_name'] ?? 'Warden';
        _hostelName = meRes['data']['warden_profile']?['hostel_name'] ?? 'Hostel';
        _userRole = meRes['data']['role'] ?? 'warden';
      }

      // We should check unread notifications. We can use OutpassProvider or ApiClient
      // Wait, WardenService could fetch notifications, or we can use ApiClient directly.
      // Let's use ApiClient to fetch unread-count if available, or just GET /notifications/
      // Actually we'll fetch notifications
    } catch (_) {}

    final dash = await WardenService.getDashboard();
    final pending = await WardenService.getPendingRequests();
    
    // For unread count, let's just fetch notifications and filter
    try {
      final notifsRes = await OutpassProvider().getNotifications();
      if (notifsRes['success'] == true && notifsRes['data'] is List) {
        _unreadCount = (notifsRes['data'] as List).where((n) => n['is_read'] == false).length;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _loading = false;
        if (dash['success'] == true) _stats = dash['data'] ?? {};
        if (pending['success'] == true && pending['data'] is List) {
          _pending = pending['data'] as List;
        }
      });
    }

    try {
      final ann = await AnnouncementService.getAnnouncements();
      if (mounted && ann['success'] == true && ann['data'] is List) {
        setState(() => _announcements = ann['data']);
      }
    } catch (_) {}
  }

  void _onNavTap(int index) {
    if (index == 1) Navigator.pushNamed(context, '/pending-requests');
    if (index == 2) Navigator.pushNamed(context, '/outside-students');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: AppDrawer(currentRole: _userRole),
      body: _loading && _stats.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader(context)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildStatGrid(),
                        const SizedBox(height: 24),
                        _buildQuickActions(),
                        const SizedBox(height: 24),
                        if (_announcements.isNotEmpty) ...[
                          Text('Active Notices', style: AppTextStyles.sectionHeader),
                          const SizedBox(height: 12),
                          _buildAnnouncementsList(),
                          const SizedBox(height: 24),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Pending Requests', style: AppTextStyles.sectionHeader),
                            if (_pending.isNotEmpty)
                              TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/pending-requests'),
                                child: Text('View All', style: AppTextStyles.bodySecondary.copyWith(color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildPendingList(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavWarden(
        currentIndex: 0,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, left: 24, right: 16, bottom: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: AppColors.gradientNavy,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('CurfewCam', style: AppTextStyles.bodySecondary.copyWith(color: Colors.white54, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                ],
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_rounded, color: Colors.white),
                    onPressed: () => Navigator.pushNamed(context, '/notifications-warden'),
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      right: 8, top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.navy, width: 1.5),
                        ),
                        child: Text('$_unreadCount', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Hello, $_wardenName', style: AppTextStyles.greeting.copyWith(color: Colors.white, fontSize: 28)),
          const SizedBox(height: 4),
          Text(
            _hostelName.isEmpty || _hostelName == 'Hostel'
                ? 'Hostel Management Overview'
                : (_hostelName.toLowerCase().contains('hostel')
                    ? '$_hostelName Overview'
                    : '$_hostelName Hostel Overview'),
            style: AppTextStyles.bodySecondary.copyWith(color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid() {
    final items = [
      _StatItem('Pending', '${_stats['pending_requests'] ?? 0}', Icons.pending_actions_rounded, AppColors.amber, AppColors.gradientAmber),
      _StatItem('Out Now', '${_stats['students_outside'] ?? 0}', Icons.directions_walk_rounded, AppColors.accentBlue, AppColors.gradientBlue),
      _StatItem('In Hostel', '${_stats['students_in_hostel'] ?? 0}', Icons.home_rounded, AppColors.success, AppColors.gradientSuccess),
      _StatItem('Late', '${_stats['late_returns'] ?? 0}', Icons.timer_off_rounded, AppColors.error, AppColors.gradientError),
    ];

    // mainAxisExtent fixes each card at exactly 112 dp tall regardless of
    // screen width, so the content (icon 32 + gap 8 + value ~24 + gap 2 +
    // label ~14 + padding 24) = ~104 dp always fits with room to spare.
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        mainAxisExtent: 120,
      ),
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (_, i) => _buildStatCard(items[i]),
    );
  }

  Widget _buildStatCard(_StatItem s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(s.icon, color: s.color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            s.value,
            style: AppTextStyles.greeting.copyWith(fontSize: 22, color: s.color, height: 1.1),
          ),
          const SizedBox(height: 2),
          Text(
            s.label,
            style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildActionBtn('Post Notice', Icons.campaign_rounded, AppColors.success, () async {
              final posted = await Navigator.pushNamed(context, '/post-announcement');
              if (posted == true) _load();
            })),
            const SizedBox(width: 8),
            Expanded(child: _buildActionBtn('Security Alerts', Icons.security, AppColors.error, () => Navigator.pushNamed(context, '/warden-detections'))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildActionBtn('Bulk Approve', Icons.checklist_rounded, AppColors.amber, () => Navigator.pushNamed(context, '/bulk-approve'))),
            const SizedBox(width: 8),
            Expanded(child: _buildActionBtn('Search', Icons.search_rounded, AppColors.accentBlue, () => Navigator.pushNamed(context, '/search-students'))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildActionBtn('Manage Accounts', Icons.manage_accounts_rounded, AppColors.accentBlue, () => Navigator.pushNamed(context, '/manage-accounts'))),
            const SizedBox(width: 8),
            Expanded(child: _buildActionBtn('Logged Complaints', Icons.report_problem_rounded, AppColors.amber, () => Navigator.pushNamed(context, '/warden-complaints'))),
          ],
        ),
        if (_userRole == 'admin_warden') ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildActionBtn('Manage Wardens', Icons.admin_panel_settings_rounded, AppColors.error, () => Navigator.pushNamed(context, '/manage-wardens'))),
              const SizedBox(width: 8),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    return Column(
      children: _announcements.map((a) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.accentIndigo.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accentIndigo.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.campaign_rounded, color: AppColors.accentIndigo, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a['title'] ?? 'Notice', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold, color: AppColors.navy)),
                    const SizedBox(height: 4),
                    Text(a['message'] ?? '', style: AppTextStyles.bodySecondary.copyWith(color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Text(a['warden_name'] ?? 'Warden', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                onPressed: () async {
                  final res = await AnnouncementService.deleteAnnouncement(a['id']);
                  if (res['success'] == true) _load();
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPendingList() {
    if (_pending.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.check_circle_rounded, size: 48, color: AppColors.success.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('All caught up!', style: AppTextStyles.cardTitle.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text('No pending requests.', style: AppTextStyles.bodySecondary),
          ],
        ),
      );
    }

    return Column(
      children: _pending.take(3).map((item) {
        final m = Map<String, dynamic>.from(item);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                await Navigator.pushNamed(context, '/request-detail', arguments: m['id']);
                _load(); // Refresh after returning
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          safeInitial(m['student_name'], fallback: 'S'),
                          style: TextStyle(color: AppColors.amber, fontWeight: FontWeight.w700, fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['student_name'] ?? 'Student', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(m['destination'] ?? m['reason'] ?? '', style: AppTextStyles.bodySecondary.copyWith(fontSize: 13)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final List<Color> gradient;
  _StatItem(this.label, this.value, this.icon, this.color, this.gradient);
}
