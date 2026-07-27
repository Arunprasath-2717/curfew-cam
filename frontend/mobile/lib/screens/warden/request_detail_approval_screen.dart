import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/status_chip.dart';
import '../../providers/warden_service.dart';
import '../../utils/string_utils.dart';

class RequestDetailApprovalScreen extends StatefulWidget {
  const RequestDetailApprovalScreen({super.key});

  @override
  State<RequestDetailApprovalScreen> createState() => _RequestDetailApprovalScreenState();
}

class _RequestDetailApprovalScreenState extends State<RequestDetailApprovalScreen> {
  bool _loading = true;
  Map<String, dynamic>? _outpass;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null) { setState(() => _loading = false); return; }
    final res = await WardenService.getOutpassDetail(id);
    if (mounted) {
      setState(() {
        _loading = false;
        if (res['success'] == true) _outpass = Map<String, dynamic>.from(res['data']);
      });
    }
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return 'N/A';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('MMM dd, yyyy • h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _outpass == null
              ? Center(child: Text('Request not found', style: AppTextStyles.bodyMain))
              : CustomScrollView(
                  slivers: [
                    // ── Gradient Header ──
                    SliverToBoxAdapter(child: _buildHeader(context)),
                    // ── Detail Body ──
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildDetailCard(),
                          const SizedBox(height: 16),
                          _buildTimingCard(),
                          const SizedBox(height: 16),
                          _buildLifecycleCard(),
                          const SizedBox(height: 28),
                          _buildActions(id),
                        ]),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final name = _outpass!['student_name'] ?? 'Student';
    final reg = _outpass!['student_register'] ?? '';
    final status = _outpass!['status'] ?? 'PENDING';

    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 4, right: 16, bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: AppColors.gradientNavy),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // App bar row
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
              const Spacer(),
              StatusChip(status: status),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 8),
          // Student info
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Center(
              child: Text(
                safeInitial(name, fallback: 'S'),
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(name, style: AppTextStyles.screenTitle.copyWith(color: Colors.white)),
          if (reg.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Reg: $reg', style: AppTextStyles.bodySecondary.copyWith(color: Colors.white54)),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('REQUEST DETAILS', style: AppTextStyles.badgeCaps.copyWith(color: AppColors.textSecondary, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _detailRow(Icons.notes_rounded, 'Reason', _outpass!['reason'] ?? 'N/A', AppColors.accentIndigo),
          const SizedBox(height: 14),
          _detailRow(Icons.place_rounded, 'Destination', _outpass!['destination'] ?? 'N/A', AppColors.accentBlue),
        ],
      ),
    );
  }

  Widget _buildTimingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TIMING', style: AppTextStyles.badgeCaps.copyWith(color: AppColors.textSecondary, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _timingBlock(Icons.logout_rounded, 'Exit', '${_outpass!['exit_date'] ?? ''}', '${_outpass!['exit_time'] ?? ''}', AppColors.error)),
              const SizedBox(width: 12),
              Expanded(child: _timingBlock(Icons.login_rounded, 'Return', '${_outpass!['expected_return_date'] ?? ''}', '${_outpass!['expected_return_time'] ?? ''}', AppColors.success)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLifecycleCard() {
    final status = (_outpass!['status'] ?? 'PENDING').toString().toUpperCase();
    final requestedAt = _formatDateTime(_outpass!['created_at']);
    final reviewedAt = _formatDateTime(_outpass!['reviewed_at']);
    final wardenName = _outpass!['approved_by_name'];
    final actualExit = _formatDateTime(_outpass!['actual_exit_time']);
    final actualReturn = _formatDateTime(_outpass!['actual_return_time']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TIMESTAMPS & LIFECYCLE', style: AppTextStyles.badgeCaps.copyWith(color: AppColors.textSecondary, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _detailRow(Icons.send_rounded, 'Requested On', requestedAt, AppColors.accentBlue),
          if (status != 'PENDING' && reviewedAt != 'N/A') ...[
            const SizedBox(height: 14),
            _detailRow(
              status == 'APPROVED' ? Icons.verified_user_rounded : Icons.gavel_rounded,
              status == 'APPROVED' ? 'Approved On' : 'Reviewed On',
              wardenName != null ? '$reviewedAt by $wardenName' : reviewedAt,
              status == 'APPROVED' ? AppColors.success : AppColors.error,
            ),
          ],
          if (actualExit != 'N/A') ...[
            const SizedBox(height: 14),
            _detailRow(Icons.sensor_door_outlined, 'Gate Exit Recorded', actualExit, AppColors.accentIndigo),
          ],
          if (actualReturn != 'N/A') ...[
            const SizedBox(height: 14),
            _detailRow(Icons.sensor_door_rounded, 'Gate Return Recorded', actualReturn, AppColors.success),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.badgeCaps.copyWith(color: AppColors.textSecondary, fontSize: 10)),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timingBlock(IconData icon, String label, String date, String time, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.badgeCaps.copyWith(color: color, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(date, style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w600, fontSize: 15)),
          Text(time, style: AppTextStyles.bodySecondary.copyWith(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildActions(String? id) {
    final status = (_outpass!['status'] ?? '').toString().toUpperCase();
    if (status != 'PENDING') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: status == 'APPROVED' ? AppColors.successGlow : AppColors.errorGlow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(status == 'APPROVED' ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: status == 'APPROVED' ? AppColors.success : AppColors.error),
            const SizedBox(width: 8),
            Text('This request has been ${status.toLowerCase()}.', style: AppTextStyles.bodyMain.copyWith(
              color: status == 'APPROVED' ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w600,
            )),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/reject-reason', arguments: id),
            icon: const Icon(Icons.close_rounded),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withOpacity(0.4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: AppColors.gradientSuccess),
              boxShadow: [BoxShadow(color: AppColors.success.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.pushNamed(context, '/approve-confirm', arguments: id),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 6),
                      Text('Approve', style: AppTextStyles.bodyMain.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
