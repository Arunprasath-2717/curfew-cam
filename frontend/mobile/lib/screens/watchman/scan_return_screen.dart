import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ScanReturnScreen extends StatelessWidget {
  const ScanReturnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final Map<String, dynamic> data = args is Map ? Map<String, dynamic>.from(args) : {};

    final studentName = data['student_name'] ?? 'Student';
    final regNo = data['register_number'] ?? 'N/A';
    final roomNo = data['room_number'] ?? 'N/A';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor, title: Row(children: [Icon(Icons.security, size: 20, color: Theme.of(context).scaffoldBackgroundColor), const SizedBox(width: 8), const Text('GateControl', style: TextStyle(fontWeight: FontWeight.bold))])),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              Container(width: 80, height: 80, decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.1), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withValues(alpha: 0.2), blurRadius: 20)]), child: const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 56)),
              const SizedBox(height: 16),
              Text('RETURN VERIFIED ✓', style: AppTextStyles.greeting.copyWith(color: const Color(0xFF22C55E))),
              Text('Access granted for campus entry', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
              const SizedBox(height: 24),
              // Student ID Card
              Container(
                decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Column(
                  children: [
                    Container(height: 8, decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)))),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: AppColors.accentBlue.withValues(alpha: 0.15),
                                child: Text(
                                  studentName.isNotEmpty ? studentName[0] : 'S',
                                  style: TextStyle(color: AppColors.accentBlue, fontSize: 28, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(studentName, style: AppTextStyles.screenTitle.copyWith(color: Theme.of(context).primaryColor)),
                                const SizedBox(height: 4),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(4)), child: Text(regNo, style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)))),
                                const SizedBox(height: 12),
                                Row(children: [Icon(Icons.meeting_room, size: 18, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)), const SizedBox(width: 4), Text('Room $roomNo', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)))]),
                              ])),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 12),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('Status Check', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9999), border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.2))), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.schedule, size: 14, color: Color(0xFF22C55E)), const SizedBox(width: 4), Text('RETURN LOGGED', style: AppTextStyles.badgeCaps.copyWith(color: const Color(0xFF22C55E)))])),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.verified_user), label: const Text('Confirm Return'), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))),
              const SizedBox(height: 8),
              Text('Entry will be logged automatically in the system archives.', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey)), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
