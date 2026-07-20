import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ScanReturnScreen extends StatelessWidget {
  const ScanReturnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor, title: Row(children: [Icon(Icons.security, size: 20, color: Theme.of(context).scaffoldBackgroundColor), SizedBox(width: 8), Text('GateControl', style: TextStyle(fontWeight: FontWeight.bold))])),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(width: 80, height: 80, decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.1), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withValues(alpha: 0.2), blurRadius: 20)]), child: Icon(Icons.check_circle, color: const Color(0xFF22C55E), size: 56)),
              const SizedBox(height: 16),
              Text('RETURN VERIFIED ✓', style: AppTextStyles.greeting.copyWith(color: const Color(0xFF22C55E))),
              Text('Access granted for campus entry', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
              const SizedBox(height: 24),
              // Student ID Card
              Container(
                decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Column(
                  children: [
                    Container(height: 8, decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)))),
                    Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(width: 96, height: 128, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).dividerColor), image: DecorationImage(image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuAbtdXdAsiFg_ol8JJibURMSibfSETI8dt_I_wTXm025TehpdYdQ1c1Y4v2dJFnlyDXtsJ_JjBjo_uR1jjqQKEYkoqoJGANHv8eT2XtRqn06pu3rVxW9gtGJmz_8Ey_ZgG5bt1xpGi-fYvITu1WkTkcKBQjWh0jDBVhnU1plO_O5zqJy64I9dPjp8xPe6Hhrs80h9xxAYLoBLBoHbwIsxD2EzYD4-BBnXHAbjL0V22LB-cHuDEqK_ID1qMpG21O7MNzUL2uFKgSTUI'), fit: BoxFit.cover))),
                              const SizedBox(width: 16),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Priya Sharma', style: AppTextStyles.screenTitle.copyWith(color: Theme.of(context).primaryColor)),
                                const SizedBox(height: 4),
                                Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(4)), child: Text('20EC204', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)))),
                                const SizedBox(height: 12),
                                Row(children: [Icon(Icons.meeting_room, size: 18, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)), SizedBox(width: 4), Text('Room B-204', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)))]),
                              ])),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(),
                          const SizedBox(height: 12),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Duration Out', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))), Text('3h 15m', style: AppTextStyles.cardTitle.copyWith(color: Theme.of(context).primaryColor))]),
                          const SizedBox(height: 12),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('Status Check', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                            Container(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9999), border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.2))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.schedule, size: 14, color: const Color(0xFF22C55E)), const SizedBox(width: 4), Text('ON-TIME', style: AppTextStyles.badgeCaps.copyWith(color: const Color(0xFF22C55E)))])),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: Icon(Icons.verified_user), label: Text('Confirm Return'), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
              const SizedBox(height: 8),
              Text('Entry will be logged automatically in the system archives.', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
