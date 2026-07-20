import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum StatusType { approved, pending, rejected, active, late, exit, returnScan, expired, overdue, returned, unknown }

class StatusChip extends StatelessWidget {
  final String? status;
  final StatusType? type;
  final String? label;

  const StatusChip({super.key, this.status, this.type, this.label});

  StatusType get _resolvedType {
    if (type != null) return type!;
    switch ((status ?? '').toUpperCase()) {
      case 'APPROVED': return StatusType.approved;
      case 'PENDING': return StatusType.pending;
      case 'REJECTED': return StatusType.rejected;
      case 'ACTIVE': return StatusType.active;
      case 'RETURNED': return StatusType.returned;
      case 'EXPIRED': return StatusType.expired;
      case 'OVERDUE': return StatusType.overdue;
      default: return StatusType.unknown;
    }
  }

  String get _label {
    if (label != null) return label!;
    return (status ?? 'UNKNOWN').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final st = _resolvedType;
    Color bg;
    Color fg;
    IconData icon;

    switch (st) {
      case StatusType.approved:
      case StatusType.returned:
        bg = AppColors.success.withOpacity(0.12);
        fg = AppColors.success;
        icon = Icons.check_circle_rounded;
        break;
      case StatusType.pending:
        bg = AppColors.amber.withOpacity(0.12);
        fg = AppColors.amber;
        icon = Icons.schedule_rounded;
        break;
      case StatusType.rejected:
        bg = AppColors.error.withOpacity(0.12);
        fg = AppColors.error;
        icon = Icons.cancel_rounded;
        break;
      case StatusType.active:
        bg = AppColors.amber.withOpacity(0.12);
        fg = AppColors.amber;
        icon = Icons.directions_walk_rounded;
        break;
      case StatusType.late:
        bg = AppColors.error.withOpacity(0.12); // Actually requirement says "amber=active/late" wait.
        // I will use amber for late as per requirement but maybe deep amber? Let's use AppColors.amber for both.
        bg = AppColors.amber.withOpacity(0.12);
        fg = AppColors.amber;
        icon = Icons.timer_off_rounded;
        break;
      case StatusType.exit:
        bg = AppColors.accentIndigo.withOpacity(0.12);
        fg = AppColors.accentIndigo;
        icon = Icons.exit_to_app_rounded;
        break;
      case StatusType.returnScan:
        bg = AppColors.accentTeal.withOpacity(0.12);
        fg = AppColors.accentTeal;
        icon = Icons.login_rounded;
        break;
      case StatusType.expired:
        bg = Colors.grey.withOpacity(0.12);
        fg = Colors.grey;
        icon = Icons.history_rounded;
        break;
      case StatusType.overdue:
        bg = AppColors.error.withOpacity(0.12);
        fg = AppColors.error;
        icon = Icons.timer_off_rounded;
        break;
      default:
        bg = Colors.grey.withOpacity(0.12);
        fg = Colors.grey;
        icon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
