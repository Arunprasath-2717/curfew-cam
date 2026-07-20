import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class ScanExitScreen extends StatelessWidget {
  const ScanExitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(backgroundColor: Color(0xFF22C55E), foregroundColor: Theme.of(context).scaffoldBackgroundColor, title: Text('EXIT VERIFIED ✓', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Success Animation
              Container(width: 96, height: 96, decoration: BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle, border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 4), boxShadow: [BoxShadow(color: Color(0xFF22C55E).withValues(alpha: 0.3), blurRadius: 24, spreadRadius: 8)]), child: Icon(Icons.check_circle, color: Theme.of(context).scaffoldBackgroundColor, size: 56)),
              const SizedBox(height: 8),
              Text('ACCESS GRANTED', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey), letterSpacing: 2)),
              const SizedBox(height: 24),
              // Student Details Card
              Container(
                decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).dividerColor)),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Container(width: 80, height: 80, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor), image: DecorationImage(image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDI-Izdx815xsFrc5buCJJGuWurCffns951DXsqvKWk2-dSs9FvQbOvatj0bKpCavMKI8_VRbiYq_qUzhYueFuVUiva42O64Udt4we7A5bKEjfWk1kD65gGX_VNIKms54Da6nopJ6fWm7cs6_d8h0Xy2c-eq76X0saEJlbRvrRO-lCupwGCmJtfzHDphDr5zLMhETiVZR8hPlWPZMM38hoTjujIRfIvLCxxgxZqNj6Ip4UdPE9IhZvQ0aS-v6lWdTTWVAIkeGdOE50'), fit: BoxFit.cover))),
                          const SizedBox(width: 16),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Arun Kumar', style: AppTextStyles.cardTitle.copyWith(color: Theme.of(context).primaryColor)),
                            Text('20CS101 • Room B-402', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                            const SizedBox(height: 8),
                            Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9999)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.verified_user, size: 14, color: const Color(0xFF22C55E)), const SizedBox(width: 4), Text('ACTIVE STATUS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF22C55E)))])),
                          ])),
                        ],
                      ),
                    ),
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                    Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildDetailRow(context, Icons.location_on, 'Destination', 'City Mall'),
                          const SizedBox(height: 16),
                          _buildDetailRow(context, Icons.assignment_ind, 'Approved by', 'Warden Block A'),
                          const SizedBox(height: 16),
                          _buildDetailRow(context, Icons.schedule, 'Expected Return', '09:00 PM Today', valueColor: const Color(0xFF22C55E)),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(color: Theme.of(context).dividerColor.withValues(alpha: 0.5), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24))),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('GATE 02 • OUTPASS #4920', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                        Text('Scan at 04:32 PM', style: AppTextStyles.badgeCaps.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey))),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: Icon(Icons.task_alt), label: Text('Confirm Exit'), style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 48), backgroundColor: Theme.of(context).primaryColor, foregroundColor: Theme.of(context).scaffoldBackgroundColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              Text('System Log: Verification Token #7721-BC', style: AppTextStyles.bodySecondary.copyWith(color: (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey).withValues(alpha: 0.6))),
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
