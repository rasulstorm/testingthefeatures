// lib/features/home/widgets/quick_action_tile.dart
import 'package:flutter/material.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';

class QuickActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const QuickActionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.getTextColor(context)),
      title: Text(
        label,
        style: AppStyles.bodyText1(
          context,
        ).copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.getSecondaryTextColor(context),
      ),
    );
  }
}
