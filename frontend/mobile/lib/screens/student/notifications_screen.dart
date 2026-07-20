import 'package:flutter/material.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_bar_widget.dart';
import '../../providers/outpass_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _loading = true;
  final _provider = OutpassProvider();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final res = await _provider.getNotifications();
      if (mounted && res['success'] == true && res['data'] is List) {
        setState(() {
          _notifications = (res['data'] as List);
          _loading = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    await _provider.markAllNotificationsRead();
    _loadNotifications();
  }

  void _onNotificationTap(Map<String, dynamic> notif) {
    final title = (notif['title'] ?? '').toString().toLowerCase();
    if (title.contains('approved')) {
      Navigator.pushReplacementNamed(context, '/active-qr');
    } else if (title.contains('rejected')) {
      Navigator.pushNamed(context, '/student-dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'Notifications',
        showBackButton: true,
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.notifications_none_rounded, size: 56, color: AppColors.textSecondary.withOpacity(0.3)),
                              const SizedBox(height: 12),
                              Text('No notifications yet', style: AppTextStyles.bodySecondary),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notif = Map<String, dynamic>.from(_notifications[index]);
                        final isRead = notif['is_read'] == true;
                        return GestureDetector(
                          onTap: () => _onNotificationTap(notif),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isRead ? Theme.of(context).colorScheme.surface : Theme.of(context).primaryColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isRead ? Theme.of(context).dividerColor : Theme.of(context).primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: isRead ? AppColors.textSecondary.withOpacity(0.08) : Theme.of(context).primaryColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isRead ? Icons.notifications_none_rounded : Icons.notifications_active_rounded,
                                    size: 18,
                                    color: isRead ? AppColors.textSecondary : Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notif['title'] ?? '',
                                        style: AppTextStyles.bodyMain.copyWith(fontWeight: isRead ? FontWeight.w500 : FontWeight.w700),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(notif['message'] ?? '', style: AppTextStyles.bodySecondary),
                                      const SizedBox(height: 6),
                                      Text(
                                        _formatTime(notif['created_at'] ?? notif['sent_at'] ?? ''),
                                        style: AppTextStyles.bodySecondary.copyWith(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8, height: 8,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  String _formatTime(String ts) {
    final dt = DateTime.tryParse(ts);
    if (dt == null) return ts;
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
