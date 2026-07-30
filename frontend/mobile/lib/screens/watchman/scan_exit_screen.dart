import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ScanExitScreen extends StatelessWidget {
  const ScanExitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final Map<String, dynamic> data = args is Map ? Map<String, dynamic>.from(args) : {};

    final studentName = data['student_name'] ?? 'Student';
    final regNo = data['register_number'] ?? 'N/A';
    final roomNo = data['room_number'] ?? 'N/A';
    final destination = data['destination'] ?? 'N/A';
    final approvedBy = data['approved_by_name'] ?? 'Warden';
    final expDate = data['expected_return_date'] ?? '';
    final expTime = data['expected_return_time'] ?? '';
    final gate = data['gate'] ?? 'GATE 01';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(backgroundColor: const Color(0xFF22C55E), foregroundColor: Theme.of(context).scaffoldBackgroundColor, title: const Text('EXIT VERIFIED ✓', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Success Animation
              Container(width: 96, height: 96, decoration: BoxDecoration(color: const Color(0xFF22C55E), shape: BoxShape.circle, border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 4), boxShadow: [BoxShadow(color: const Color(0xFF22C55E).withValues(alpha: 0.3), blurRadius: 24, spreadRadius: 8)]), child: Icon(Icons.check_circle, color: Theme.of(context).scaffoldBackgroundColor, size: 56)),
              const SizedBox(height: 8),
              Text('ACCESS GRANTED', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey), letterSpacing: 2)),
              const SizedBox(height: 24),
              // Student Details Card
              Container(
                decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
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
                            Text(studentName, style: AppTextStyles.cardTitle.copyWith(color: Theme.of(context).primaryColor)),
                            Text('$regNo • Room $roomNo', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                            const SizedBox(height: 8),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9999)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.verified_user, size: 14, color: Color(0xFF22C55E)), SizedBox(width: 4), Text('EXIT GRANTED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF22C55E)))])),
                          ])),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildDetailRow(context, Icons.location_on, 'Destination', destination),
                          const SizedBox(height: 16),
                          _buildDetailRow(context, Icons.assignment_ind, 'Approved by', approvedBy),
                          const SizedBox(height: 16),
                          _buildDetailRow(context, Icons.schedule, 'Expected Return', '$expDate $expTime'.trim(), valueColor: const Color(0xFF22C55E)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.5), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24))),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('$gate • SCAN VERIFIED', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                        Text('Just now', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.task_alt), label: const Text('Confirm Exit'), style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey), letterSpacing: 0.5)),
          Text(value, style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w600, color: valueColor ?? Theme.of(context).primaryColor)),
        ]),
      ],
    );
  }
}
