import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class HelpSupportWatchmanScreen extends StatelessWidget {
  const HelpSupportWatchmanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor, title: Row(children: [Icon(Icons.security, size: 20), SizedBox(width: 8), Text('GateControl', style: TextStyle(fontWeight: FontWeight.bold))])),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Help & Support', style: AppTextStyles.screenTitle),
              Text('Resources for watchmen and on-site staff.', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: Icon(Icons.contact_support), label: Text('Contact Warden'), style: ElevatedButton.styleFrom(minimumSize: Size(0, 48), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
                  const SizedBox(width: 16),
                  Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: Icon(Icons.call), label: Text('Emergency'), style: OutlinedButton.styleFrom(minimumSize: Size(0, 48), foregroundColor: Theme.of(context).primaryColor, side: BorderSide(color: Theme.of(context).dividerColor), backgroundColor: Theme.of(context).scaffoldBackgroundColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
                ],
              ),
              const SizedBox(height: 32),
              Text('Frequently Asked Questions', style: AppTextStyles.sectionHeader),
              const SizedBox(height: 16),
              _buildFaqItem(context, 'How to scan a QR code?', 'Open the "Scanner" tab from the bottom navigation. Point your camera at the student\'s digital outpass. The system will automatically validate the pass and show a green "Approved" checkmark.'),
              const SizedBox(height: 8),
              _buildFaqItem(context, 'Manual Entry of IDs', 'If the QR code is unreadable, tap the "Enter ID Manually" button on the scanner screen. Type the student\'s registration number and tap "Validate".'),
              const SizedBox(height: 8),
              _buildFaqItem(context, 'System Offline?', 'In case of internet failure, please record all entries/exits in the physical logbook. Syncing will occur automatically once the network is restored.'),
              const SizedBox(height: 32),
              // Report a Problem
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.report_problem, color: Theme.of(context).colorScheme.secondary), SizedBox(width: 8), Text('Report a Problem', style: AppTextStyles.sectionHeader)]),
                    const SizedBox(height: 16),
                    Text('DESCRIBE THE ISSUE', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                    const SizedBox(height: 8),
                    TextField(maxLines: 4, decoration: InputDecoration(hintText: 'Please provide details about the software bug or gate physical issue...', filled: true, fillColor: Theme.of(context).scaffoldBackgroundColor, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).dividerColor)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2)))),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Text('Submit Report')),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String title, String content) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)]),
      child: ExpansionTile(
        title: Text(title, style: AppTextStyles.cardTitle),
        children: [Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child: Text(content, style: AppTextStyles.bodyMain.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))))],
      ),
    );
  }
}
