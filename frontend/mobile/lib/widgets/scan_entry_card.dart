import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class ScanEntryCard extends StatelessWidget {
  final String initials;
  final String name;
  final String details;
  final bool isExit;
  final bool faded;

  const ScanEntryCard({
    super.key,
    required this.initials,
    required this.name,
    required this.details,
    required this.isExit,
    this.faded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: faded ? 0.6 : 1.0,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.bodyMain.copyWith(fontWeight: FontWeight.bold)),
                  Text(details, style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isExit ? Theme.of(context).colorScheme.error : Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                isExit ? 'EXIT' : 'RETURN',
                style: AppTextStyles.badgeCaps.copyWith(color: Theme.of(context).scaffoldBackgroundColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
