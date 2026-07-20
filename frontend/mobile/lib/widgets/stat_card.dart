import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String count;
  final IconData icon;
  final Color color;
  final double progress; // 0.0 to 1.0

  const StatCard({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color == Theme.of(context).primaryColor 
            ? Theme.of(context).primaryColor.withOpacity(0.1) 
            : Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: color == Theme.of(context).primaryColor 
              ? Theme.of(context).dividerColor 
              : color.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: AppTextStyles.badgeCaps.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor, // Using navy for numbers
            ),
          ),
          const Spacer(),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
