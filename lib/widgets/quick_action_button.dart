import 'package:flutter/material.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';

class QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const QuickActionButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: AppColors.getTextColor(context),
        backgroundColor: AppColors.getCardBackgroundColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: AppStyles.borderRadiusAll(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 4,
      ),
    );
  }
}
