import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class OfflineModeNoticeScreen extends StatelessWidget {
  const OfflineModeNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor, title: Row(children: [Icon(Icons.security, size: 20), SizedBox(width: 8), Text('GateControl', style: TextStyle(fontWeight: FontWeight.bold))])),
      body: SafeArea(
        child: Column(
          children: [
            // Warning Banner
            Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), color: Theme.of(context).colorScheme.secondary, child: Row(children: [Icon(Icons.cloud_off, color: Theme.of(context).scaffoldBackgroundColor), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('No Internet Connection', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).scaffoldBackgroundColor)), Text('Scans will be queued and synced when online', style: AppTextStyles.badgeCaps.copyWith(color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9)))]))])),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Sync Status Card
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Container(width: 64, height: 64, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, shape: BoxShape.circle), child: Icon(Icons.sync_problem, size: 32, color: Theme.of(context).colorScheme.secondary)),
                              Container(padding: EdgeInsets.all(6), decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle, border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2)), child: Text('3', style: TextStyle(color: Theme.of(context).scaffoldBackgroundColor, fontSize: 10, fontWeight: FontWeight.bold))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('3 pending syncs', style: AppTextStyles.cardTitle),
                          const SizedBox(height: 8),
                          Text('Your local scan data is secured and encrypted. Please reconnect to sync with the central server.', textAlign: TextAlign.center, style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(onPressed: () {}, icon: Icon(Icons.refresh), label: Text('Retry Connection'), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Offline Scanner Simulation area
                    Align(alignment: Alignment.centerLeft, child: Text('Offline Scanner', style: AppTextStyles.sectionHeader)),
                    const SizedBox(height: 16),
                    Container(
                      height: 240, width: double.infinity,
                      decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).colorScheme.secondary, width: 4)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(16)), child: Icon(Icons.qr_code_2, size: 64, color: Theme.of(context).primaryColor)),
                          const SizedBox(height: 16),
                          Text('Position the QR code within the frame\nto scan while offline', textAlign: TextAlign.center, style: AppTextStyles.bodySecondary.copyWith(color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Queued Items', style: AppTextStyles.sectionHeader), Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(4)), child: Text('LOCAL STORAGE', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))))]),
                    const SizedBox(height: 16),
                    _buildQueuedItem(context, 'Rahul Sharma', 'Outpass #8829 • 10:24 AM'),
                    const SizedBox(height: 8),
                    _buildQueuedItem(context, 'Ananya Iyer', 'Outpass #8831 • 11:05 AM'),
                    const SizedBox(height: 8),
                    _buildQueuedItem(context, 'Vikram Singh', 'Outpass #8840 • 11:18 AM'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueuedItem(BuildContext context, String name, String detail) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.person, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold)), Text(detail, style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)))])),
          Icon(Icons.schedule_send, color: Theme.of(context).colorScheme.secondary),
        ],
      ),
    );
  }
}
