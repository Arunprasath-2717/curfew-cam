import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';

class ReturnVerificationScreen extends StatelessWidget {
  const ReturnVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor, title: Text('CurfewCam', style: TextStyle(fontWeight: FontWeight.w600))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('Mark Your Return', style: AppTextStyles.screenTitle),
              const SizedBox(height: 8),
              Text('Show this QR at the gate to check in', style: AppTextStyles.bodyMain.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
              const SizedBox(height: 24),
              // QR Card
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity, height: 250,
                      decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
                      child: Center(child: Icon(Icons.qr_code_2, size: 180, color: Theme.of(context).primaryColor)),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Theme.of(context).dividerColor.withOpacity(0.3), borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)),
                      child: Row(children: [
                        Container(width: 40, height: 40, decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle), child: Icon(Icons.person, color: Theme.of(context).scaffoldBackgroundColor)),
                        const SizedBox(width: 12),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Arun Kumar', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold)),
                          Text('20CS101', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                        ]),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Status chip
              Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, borderRadius: BorderRadius.circular(9999)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('YOU ARE CURRENTLY OUT', style: AppTextStyles.badgeCaps.copyWith(color: Theme.of(context).scaffoldBackgroundColor)),
                ]),
              ),
              const SizedBox(height: 24),
              // Time info
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Row(children: [
                  Icon(Icons.schedule, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Out Since', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                    Text('18:45, Today', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('Deadline', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                    Text('21:30', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.error)),
                  ]),
                ]),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: Icon(Icons.support_agent), label: Text('Get Help'), style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16), foregroundColor: Theme.of(context).primaryColor, side: BorderSide(color: Theme.of(context).dividerColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))))),
                const SizedBox(width: 16),
                Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: Icon(Icons.share), label: Text('Share'), style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16), foregroundColor: Theme.of(context).primaryColor, side: BorderSide(color: Theme.of(context).dividerColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))))),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
