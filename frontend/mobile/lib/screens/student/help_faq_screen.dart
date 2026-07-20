import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_bar_widget.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  static const _faqs = [
    {
      'q': 'How do I request an outpass?',
      'a': 'Go to your Dashboard, tap "New Outpass", fill in the details (destination, dates, reason), and submit. Your warden will review and approve or reject it.',
    },
    {
      'q': 'How long does approval take?',
      'a': 'Most requests are reviewed within a few hours. You\'ll receive a push notification when your warden responds.',
    },
    {
      'q': 'What happens if I return late?',
      'a': 'Late returns are flagged in the system. Your warden receives an alert and a violation may be recorded on your profile.',
    },
    {
      'q': 'Can I cancel an approved outpass?',
      'a': 'Currently, you cannot cancel an outpass once approved. Contact your warden directly if plans change.',
    },
    {
      'q': 'How does QR scanning work?',
      'a': 'Once approved, a QR code is generated. The watchman scans it when you exit and again when you return to log your movement.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(title: 'Help & Support', showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Contact Cards ──
          Row(
            children: [
              Expanded(child: _ContactCard(
                icon: Icons.email_rounded,
                color: AppColors.accentBlue,
                title: 'Email Us',
                detail: 'support@hostel.edu',
              )),
              const SizedBox(width: 12),
              Expanded(child: _ContactCard(
                icon: Icons.access_time_rounded,
                color: AppColors.accentTeal,
                title: 'Office Hours',
                detail: '9 AM – 6 PM\nMon – Sat',
              )),
            ],
          ),
          const SizedBox(height: 12),
          _ContactCard(
            icon: Icons.phone_rounded,
            color: AppColors.success,
            title: 'Emergency Hostel Line',
            detail: '+91 98765 43210',
          ),

          const SizedBox(height: 28),

          // ── FAQ ──
          Text('Frequently Asked Questions', style: AppTextStyles.sectionHeader),
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: List.generate(_faqs.length, (i) {
                final faq = _faqs[i];
                return Column(
                  children: [
                    if (i > 0) Divider(height: 1, color: Theme.of(context).dividerColor, indent: 16, endIndent: 16),
                    ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      shape: const Border(),
                      collapsedShape: const Border(),
                      leading: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.accentIndigo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text('${i + 1}', style: TextStyle(
                          color: AppColors.accentIndigo, fontWeight: FontWeight.w700, fontSize: 13,
                        )),
                      ),
                      title: Text(faq['q']!, style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w600)),
                      children: [
                        Text(faq['a']!, style: AppTextStyles.bodySecondary.copyWith(height: 1.5)),
                      ],
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String detail;

  const _ContactCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.badgeCaps.copyWith(color: AppColors.textSecondary, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(detail, style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
