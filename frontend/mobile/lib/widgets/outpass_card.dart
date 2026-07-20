import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'status_chip.dart';

class OutpassCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final StatusType statusType;
  final String statusLabel;
  final VoidCallback? onTap;

  const OutpassCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.statusType,
    required this.statusLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color iconBgColor;
    Color iconColor;

    switch (statusType) {
      case StatusType.approved:
      case StatusType.returned:
        iconBgColor = const Color(0xFF22C55E).withOpacity(0.1);
        iconColor = const Color(0xFF22C55E);
        break;
      case StatusType.rejected:
      case StatusType.late:
      case StatusType.exit:
      case StatusType.overdue:
        iconBgColor = Theme.of(context).colorScheme.error.withOpacity(0.1);
        iconColor = Theme.of(context).colorScheme.error;
        break;
      case StatusType.pending:
        iconBgColor = Theme.of(context).primaryColor.withOpacity(0.1);
        iconColor = Theme.of(context).primaryColor;
        break;
      case StatusType.active:
        iconBgColor = Theme.of(context).colorScheme.secondary.withOpacity(0.1);
        iconColor = Theme.of(context).colorScheme.secondary;
        break;
      case StatusType.returnScan:
        iconBgColor = const Color(0xFF22C55E).withOpacity(0.1);
        iconColor = const Color(0xFF22C55E);
        break;
      case StatusType.expired:
      case StatusType.unknown:
        iconBgColor = Colors.grey.withOpacity(0.1);
        iconColor = Colors.grey;
        break;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppTextStyles.cardTitle, overflow: TextOverflow.ellipsis),
                        Text(subtitle, style: AppTextStyles.bodySecondary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusChip(type: statusType, label: statusLabel),
          ],
        ),
      ),
    );
  }
}
