import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar_widget.dart';
import '../../widgets/bottom_nav_student.dart';
import '../../widgets/status_chip.dart';
import '../../providers/outpass_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedFilter = 0; // 0: All, 1: Approved, 2: Rejected, 3: Pending
  final List<String> _filters = ['All', 'Approved', 'Rejected', 'Pending'];
  bool _isLoading = true;
  List<dynamic> _history = [];
  final _outpassProvider = OutpassProvider();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final res = await _outpassProvider.getOutpassHistory();
      if (!mounted) return;
      
      setState(() {
        if (res['success'] == true && res['data'] is List) {
          _history = (res['data'] as List);
        }
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDuration(String? outTime, String? inTime) {
    if (outTime == null || inTime == null) return '—';
    final out = DateTime.tryParse(outTime);
    final inn = DateTime.tryParse(inTime);
    if (out == null || inn == null) return '—';
    
    final diff = inn.difference(out);
    return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
  }

  void _onNavTap(int index) {
    if (index == 0) Navigator.of(context).popUntil((route) => route.isFirst);
    if (index == 1) Navigator.pushReplacementNamed(context, '/active-qr');
    if (index == 3) Navigator.pushReplacementNamed(context, '/student-profile');
  }

  @override
  Widget build(BuildContext context) {
    final filteredHistory = _history.where((item) {
      final status = item['status'];
      if (_selectedFilter == 1) return status == 'APPROVED' || status == 'ACTIVE' || status == 'RETURNED';
      if (_selectedFilter == 2) return status == 'REJECTED';
      if (_selectedFilter == 3) return status == 'PENDING';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBarWidget(
        title: 'History',
        showBackButton: false,
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(_filters.length, (index) {
                final isActive = _selectedFilter == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedFilter = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? Theme.of(context).primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isActive ? Theme.of(context).primaryColor : AppColors.border),
                      ),
                      child: Text(
                        _filters[index],
                        style: TextStyle(color: isActive ? Colors.white : AppColors.textSecondary),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredHistory.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_rounded, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
                              const SizedBox(height: 16),
                              Text('No history found', style: AppTextStyles.cardTitle.copyWith(color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              Text('Your past requests will appear here.', style: AppTextStyles.bodySecondary, textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchData,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredHistory.length,
                          itemBuilder: (context, index) {
                            final item = filteredHistory[index];
                            return _HistoryCard(
                              item: item,
                              duration: _formatDuration(item['actual_exit_time'], item['actual_return_time']),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavStudent(
        currentIndex: 2,
        onTap: _onNavTap,
        hasApprovedRequest: _history.any((r) => r['status'] == 'APPROVED' || r['status'] == 'ACTIVE'),
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final String duration;

  const _HistoryCard({required this.item, required this.duration});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(widget.item['reason'] ?? 'Reason', style: AppTextStyles.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                StatusChip(status: widget.item['status'] ?? 'PENDING'),
              ],
            ),
            const SizedBox(height: 8),
            Text('Dest: ${widget.item['destination']}', style: AppTextStyles.bodyMain),
            const SizedBox(height: 4),
            Text('Duration: ${widget.duration}', style: AppTextStyles.bodySecondary),
            
            if (_expanded) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              if (widget.item['actual_exit_time'] != null) Text('Out: ${widget.item['actual_exit_time']}', style: AppTextStyles.bodySecondary),
              if (widget.item['actual_return_time'] != null) Text('In: ${widget.item['actual_return_time']}', style: AppTextStyles.bodySecondary),
              if (widget.item['approved_by_name'] != null) Text('Warden: ${widget.item['approved_by_name']}', style: AppTextStyles.bodySecondary),
              if (widget.item['warden_notes'] != null && strNotEmpty(widget.item['warden_notes'])) Text('Note: ${widget.item['warden_notes']}', style: AppTextStyles.bodySecondary),
              if (widget.item['rejection_reason'] != null && strNotEmpty(widget.item['rejection_reason'])) Text('Rejection Reason: ${widget.item['rejection_reason']}', style: AppTextStyles.bodySecondary.copyWith(color: AppColors.error)),
            ],
          ],
        ),
      ),
    );
  }

  bool strNotEmpty(dynamic str) {
    return str != null && str.toString().trim().isNotEmpty;
  }
}
