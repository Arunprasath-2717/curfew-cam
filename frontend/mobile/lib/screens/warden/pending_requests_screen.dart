import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/status_chip.dart';
import '../../providers/warden_service.dart';
import '../../utils/string_utils.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  bool _loading = true;
  List<dynamic> _requests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await WardenService.getPendingRequests();
    if (mounted) {
      setState(() {
        _loading = false;
        if (res['success'] == true && res['data'] is List) {
          _requests = res['data'] as List;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pending Requests'),
        actions: [
          if (_requests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${_requests.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _requests.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Column(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 64, color: AppColors.success.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text('All Clear!', style: AppTextStyles.screenTitle.copyWith(color: AppColors.textSecondary)),
                            const SizedBox(height: 6),
                            Text('No pending requests to review.', style: AppTextStyles.bodySecondary),
                          ],
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _requests.length,
                      itemBuilder: (context, i) {
                        final item = Map<String, dynamic>.from(_requests[i]);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () async {
                                await Navigator.pushNamed(context, '/request-detail', arguments: item['id']);
                                _load(); // Refresh after returning
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Theme.of(context).dividerColor),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
                                ),
                                child: Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 48, height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: AppColors.gradientAmber),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Center(
                                        child: Text(
                                          safeInitial(item['student_name'], fallback: 'S'),
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item['student_name'] ?? 'Student', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.place_rounded, size: 14, color: AppColors.textSecondary),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  item['destination'] ?? '',
                                                  style: AppTextStyles.bodySecondary.copyWith(fontSize: 13),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (item['created_at'] != null) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(Icons.schedule_rounded, size: 14, color: AppColors.accentBlue),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    'Requested: ${item['created_at'].toString().split('T').first} ${item['created_at'].toString().split('T').length > 1 ? item['created_at'].toString().split('T')[1].substring(0, 5) : ''}',
                                                    style: AppTextStyles.bodySecondary.copyWith(fontSize: 12, color: AppColors.accentBlue),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (item['reason'] != null && item['reason'].toString().isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                Icon(Icons.notes_rounded, size: 14, color: AppColors.textSecondary),
                                                const SizedBox(width: 4),
                                                Flexible(
                                                  child: Text(
                                                    item['reason'],
                                                    style: AppTextStyles.bodySecondary.copyWith(fontSize: 12),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const StatusChip(status: 'PENDING'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
