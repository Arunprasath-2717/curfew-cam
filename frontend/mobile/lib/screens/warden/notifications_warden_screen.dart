import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

import 'package:provider/provider.dart';
import '../../providers/outpass_provider.dart';

class NotificationsWardenScreen extends StatefulWidget {
  const NotificationsWardenScreen({super.key});

  @override
  State<NotificationsWardenScreen> createState() => _NotificationsWardenScreenState();
}

class _NotificationsWardenScreenState extends State<NotificationsWardenScreen> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final res = await context.read<OutpassProvider>().getNotifications();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true && res['data'] != null) {
          _notifications = res['data'] is List ? res['data'] : [];
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
        title: Text('CurfewCam', style: TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(icon: Icon(Icons.menu), onPressed: () {}),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
              Positioned(top: 12, right: 12, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).primaryColor, width: 2)))),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notifications', style: AppTextStyles.greeting.copyWith(color: Theme.of(context).primaryColor)),
                      Text('Stay updated on hostel activities', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                    ],
                  ),
                  TextButton(onPressed: () {}, child: Text('MARK ALL READ', style: AppTextStyles.badgeCaps.copyWith(color: Theme.of(context).primaryColor))),
                ],
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 24),
              
              if (_isLoading)
                Center(child: CircularProgressIndicator())
              else if (_notifications.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.notifications_off, size: 64, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey).withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text('No more notifications', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildNotificationItem(context, 
                        'UPDATE', 
                        item['created_at'] ?? 'Just now', 
                        Theme.of(context).primaryColor, 
                        Icons.info,
                        item['title'] ?? 'Notification', 
                        item['message'] ?? '',
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, String badgeText, String timeText, Color color, IconData icon, String title, String body, {List<Widget>? actions, bool showArrow = false}) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)))),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(badgeText, style: AppTextStyles.badgeCaps.copyWith(color: color))),
                              Text(timeText, style: TextStyle(fontSize: 11, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey), fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(title, style: AppTextStyles.cardTitle),
                          const SizedBox(height: 4),
                          Text(body, style: AppTextStyles.bodyMain.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                          if (actions != null) ...[
                            const SizedBox(height: 16),
                            Row(children: actions),
                          ],
                          if (showArrow) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text('View details', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_forward, size: 16, color: Theme.of(context).primaryColor),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
