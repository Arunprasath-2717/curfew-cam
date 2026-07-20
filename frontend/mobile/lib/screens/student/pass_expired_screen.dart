import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/primary_button.dart';

class PassExpiredScreen extends StatelessWidget {
  const PassExpiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('CurfewCam', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(icon: Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Status Alert', style: AppTextStyles.screenTitle),
              const SizedBox(height: 24),
              // Warning Card
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withOpacity(0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).colorScheme.secondary)),
                child: Column(children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.warning, color: Theme.of(context).colorScheme.secondary)),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Your Pass Has Expired', style: AppTextStyles.sectionHeader),
                      const SizedBox(height: 4),
                      Text('Your authorized absence window has closed. Please report to the gate immediately to mark your return.', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                    ])),
                  ]),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(child: Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)), child: Column(children: [
                      Text('RETURN TIME', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                      const SizedBox(height: 4),
                      Text('09:00 PM', style: AppTextStyles.cardTitle),
                    ]))),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 16.0), child: Icon(Icons.arrow_forward, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                    Expanded(child: Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)), child: Column(children: [
                      Text('CURRENT TIME', style: AppTextStyles.badgeCaps.copyWith(color: Theme.of(context).colorScheme.error)),
                      const SizedBox(height: 4),
                      Text('09:15 PM', style: AppTextStyles.cardTitle.copyWith(color: Theme.of(context).colorScheme.error)),
                    ]))),
                  ]),
                ]),
              ),
              const SizedBox(height: 24),
              // QR Interface
              Container(
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).primaryColor, width: 2)),
                child: Column(children: [
                  Container(
                    width: 192, height: 192,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor),
                      image: const DecorationImage(image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuAZYWGY8mRzlFttBxHQIri2jm_j_-oY2FSovOxzcRA9y6EnrCubHqFpXbS-8aoQTgOKudR44SIQc_K_Dq7Kaqwl4zHhZmysF2r-MqlfvrJg4Tvgm6eTQxIyme1lPRHBT3g5S8-kKZtn1Nb81xoUGWELUxXnxjBLrVWzFf6sNsfayiwBx-rbJS8fSEvlwTTS48X_nM6ctZI8RyRafxIppMgJT619UIpSiKR5IAaoiteNrvTU4XS_B1KvxPm-ijhoCEmGWvRygO7qcN0'), fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('SCAN AT GATE TO VERIFY', style: AppTextStyles.badgeCaps.copyWith(color: Theme.of(context).primaryColor, letterSpacing: 2)),
                ]),
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Mark Return Now', icon: Icons.how_to_reg, onPressed: () {}),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.support_agent),
                label: Text('Contact Warden'),
                style: OutlinedButton.styleFrom(minimumSize: Size(double.infinity, 48), foregroundColor: Theme.of(context).primaryColor, side: BorderSide(color: Theme.of(context).primaryColor), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 8),
                  Text('DESTINATION', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                  const SizedBox(height: 4),
                  Text('City Mall Central', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold)),
                ]))),
                const SizedBox(width: 16),
                Expanded(child: Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.pin_drop, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 8),
                  Text('BLOCK', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                  const SizedBox(height: 4),
                  Text('Hostel Block A', style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold)),
                ]))),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
