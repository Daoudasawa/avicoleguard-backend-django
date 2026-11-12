import 'package:flutter/material.dart';
import 'package:avicoleguard_mobile/core/constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusBadge.flockStatus(String status) {
    final isActif = status.toLowerCase() == 'active';
    return StatusBadge(
      label: isActif ? 'Actif' : 'Clôturé',
      backgroundColor: isActif
          ? AppColors.alertSuccess.withAlpha(25)
          : AppColors.textSecondary.withAlpha(25),
      textColor: isActif ? AppColors.alertSuccess : AppColors.textSecondary,
      icon: isActif ? Icons.check_circle_outline : Icons.lock_outline,
    );
  }

  factory StatusBadge.alertLevel(String level) {
    Color bg;
    Color text;
    String labelText;
    IconData ic;

    switch (level.toLowerCase()) {
      case 'critique':
        bg = AppColors.alertCritical.withAlpha(30);
        text = AppColors.alertCritical;
        labelText = 'Critique';
        ic = Icons.warning_rounded;
        break;
      case 'preoccupant':
        bg = AppColors.alertWarning.withAlpha(30);
        text = AppColors.alertWarning;
        labelText = 'Préoccupant';
        ic = Icons.report_problem_outlined;
        break;
      case 'attention':
        bg = AppColors.secondary.withAlpha(35);
        text = const Color(0xFF9E7700);
        labelText = 'Attention';
        ic = Icons.info_outline;
        break;
      default:
        bg = AppColors.alertInfo.withAlpha(25);
        text = AppColors.alertInfo;
        labelText = 'Info';
        ic = Icons.info_outline;
    }

    return StatusBadge(
      label: labelText,
      backgroundColor: bg,
      textColor: text,
      icon: ic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
