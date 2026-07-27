import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bottom_nav_student.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/status_chip.dart';
import '../../providers/outpass_provider.dart';
import '../../providers/auth_service.dart';
import 'dart:async';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Map<String, dynamic>? _activeRequest;
  List<dynamic> _recentRequests = [];
  String _studentName = 'Student';
  int _unreadCount = 0;
  bool _isLoading = true;
  final _outpassProvider = OutpassProvider();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  Timer? _autoReturnTimer;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _fetchData();
    _autoReturnTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      // Removed auto detect
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted && _activeRequest != null) {
        final st = _activeRequest!['status'];
        if (st == 'ACTIVE' || st == 'APPROVED') {
          setState(() {}); // trigger rebuild for countdown
        }
      }
    });
  }

  @override
  void dispose() {
    _autoReturnTimer?.cancel();
    _countdownTimer?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    final meRes = await AuthService.getMe();
    if (meRes['success'] == true && meRes['data'] != null) {
      _studentName = meRes['data']['full_name'] ?? meRes['data']['first_name'] ?? 'Student';
    }

    try {
      final currentRes = await _outpassProvider.getCurrentOutpass();
      final historyRes = await _outpassProvider.getOutpassHistory();
      final notifsRes = await _outpassProvider.getNotifications();
      if (!mounted) return;

      setState(() {
        _activeRequest = (currentRes['success'] == true) ? currentRes['data'] : null;
        if (historyRes['success'] == true && historyRes['data'] is List) {
          _recentRequests = (historyRes['data'] as List).take(3).toList();
        }
        if (notifsRes['success'] == true && notifsRes['data'] is List) {
          _unreadCount = (notifsRes['data'] as List).where((n) => n['is_read'] == false).length;
        }
        _isLoading = false;
      });
      _animCtrl.forward(from: 0);
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }



  void _onNavTap(int index) {
    if (index == 1) {
      if (_activeRequest == null || (_activeRequest!['status'] != 'APPROVED' && _activeRequest!['status'] != 'ACTIVE')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Get your request approved first.')),
        );
        return;
      }
      Navigator.pushNamed(context, '/active-qr');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/history');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(currentRole: 'student'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnim,
              child: RefreshIndicator(
                onRefresh: _fetchData,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // ── Gradient Header ──
                    SliverToBoxAdapter(child: _buildHeader(context)),
                    // ── Body ──
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildStatusCard(),
                          const SizedBox(height: 20),
                          _buildNewOutpassButton(),
                          const SizedBox(height: 28),
                          Text('Recent Requests', style: AppTextStyles.sectionHeader),
                          const SizedBox(height: 14),
                          _buildRecentRequests(),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavStudent(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        hasApprovedRequest: _activeRequest != null && (_activeRequest!['status'] == 'APPROVED' || _activeRequest!['status'] == 'ACTIVE'),
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
              _buildNotifBell(),
            ],
          ),
          const SizedBox(height: 16),
          Text(_getGreeting(), style: AppTextStyles.bodyMain.copyWith(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(_studentName, style: AppTextStyles.greeting.copyWith(color: Colors.white, fontSize: 28)),
          const SizedBox(height: 6),
          Text('Campus secure. Check your status below.', style: AppTextStyles.bodySecondary.copyWith(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildNotifBell() {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_rounded, color: Colors.white),
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
        ),
        if (_unreadCount > 0)
          Positioned(
            right: 8, top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text('$_unreadCount', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  String _getCountdownText() {
    if (_activeRequest == null || _activeRequest!.isEmpty) return '';
    final dateStr = _activeRequest!['expected_return_date'];
    final timeStr = _activeRequest!['expected_return_time'];
    if (dateStr == null || timeStr == null) return '';
    
    final returnTime = DateTime.tryParse('$dateStr $timeStr');
    if (returnTime == null) return '';
    
    final diff = returnTime.difference(DateTime.now());
    if (diff.isNegative) {
      return 'OVERDUE by ${diff.abs().inHours}h ${diff.abs().inMinutes.remainder(60)}m';
    }
    
    final days = diff.inDays;
    final hours = diff.inHours.remainder(24);
    final minutes = diff.inMinutes.remainder(60);
    
    if (days > 0) {
      return 'Returns in ${days}d ${hours}h ${minutes}m';
    } else {
      return 'Returns in ${hours}h ${minutes}m';
    }
  }

  Widget _buildStatusCard() {
    if (_activeRequest == null || _activeRequest!.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.blueGlow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.maps_home_work_rounded, size: 28, color: AppColors.accentBlue),
            ),
            const SizedBox(height: 16),
            Text('No Active Outpass', style: AppTextStyles.cardTitle),
            const SizedBox(height: 4),
            Text('You are currently inside the hostel.', style: AppTextStyles.bodySecondary),
          ],
        ),
      );
    }

    final status = _activeRequest!['status'] ?? '';
    final isOverdue = _getCountdownText().startsWith('OVERDUE');
    final exitDate = _activeRequest!['exit_date'];
    final returnDate = _activeRequest!['expected_return_date'];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CURRENT STATUS', style: AppTextStyles.badgeCaps.copyWith(color: AppColors.textSecondary, letterSpacing: 1.2)),
              StatusChip(status: status),
            ],
          ),
          const SizedBox(height: 16),
          Text(_activeRequest!['destination']?.toString().isNotEmpty == true ? _activeRequest!['destination'] : 'Unknown', style: AppTextStyles.screenTitle),
          const SizedBox(height: 14),
          
          if (exitDate != null && exitDate.toString().isNotEmpty) ...[
            _infoRow(Icons.calendar_today_rounded, 'Leave', '${_activeRequest!['exit_date']} ${_activeRequest!['exit_time'] ?? ''}'),
            const SizedBox(height: 8),
          ],
          
          if (returnDate != null && returnDate.toString().isNotEmpty) ...[
            _infoRow(Icons.update_rounded, 'Return', '${_activeRequest!['expected_return_date']} ${_activeRequest!['expected_return_time'] ?? ''}'),
            const SizedBox(height: 16),
          ],
          
          if (status == 'ACTIVE' || status == 'APPROVED') ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isOverdue ? AppColors.error.withOpacity(0.1) : AppColors.accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isOverdue ? AppColors.error : AppColors.accentBlue),
              ),
              child: Text(
                _getCountdownText(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isOverdue ? AppColors.error : AppColors.accentBlue,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          

        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.accentBlue),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.badgeCaps.copyWith(color: AppColors.textSecondary, fontSize: 10)),
            Text(value, style: AppTextStyles.bodySecondary.copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }

  Widget _buildNewOutpassButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: AppColors.gradientNavy),
        boxShadow: [BoxShadow(color: AppColors.navy.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/request-step1'),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_circle_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text('New Outpass Request', style: AppTextStyles.cardTitle.copyWith(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentRequests() {
    if (_recentRequests.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text('No recent requests.', style: AppTextStyles.bodySecondary),
      );
    }
    return Column(
      children: _recentRequests.map((req) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pushNamed(context, '/outpass-detail', arguments: req['id']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.accentIndigo.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.place_rounded, color: AppColors.accentIndigo, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(req['destination'] ?? 'Destination', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('${req['exit_date'] ?? ''}', style: AppTextStyles.bodySecondary.copyWith(fontSize: 13)),
                        ],
                      ),
                    ),
                    StatusChip(status: req['status']),
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
