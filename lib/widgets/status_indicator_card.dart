import 'package:flutter/material.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/l10n/app_localizations.dart';

class StatusIndicator {
  final String label;
  final String value;
  final String subLabel;
  final IconData icon;
  final Color? iconColor;
  final bool hasAlert;

  StatusIndicator({
    required this.label,
    required this.value,
    required this.subLabel,
    required this.icon,
    this.iconColor,
    this.hasAlert = false,
  });
}

class CompactStatusIndicatorCard extends StatelessWidget {
  final StatusIndicator indicator;

  const CompactStatusIndicatorCard({Key? key, required this.indicator})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppStyles.cardDecoration(
        context,
      ).copyWith(borderRadius: AppStyles.borderRadiusAll(12)),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                indicator.icon,
                size: 28,
                color: indicator.iconColor ?? AppColors.primaryAccent,
              ),
              if (indicator.hasAlert)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Icon(
                    Icons.warning_amber,
                    color: AppColors.error,
                    size: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            indicator.value,
            style: AppStyles.bodyText2(context).copyWith(
              color: AppColors.getTextColor(context),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            indicator.label,
            style: AppStyles.caption(context).copyWith(
              color: AppColors.getSecondaryTextColor(context),
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
