// lib/widgets/status_indicator_card.dart
// --- REDESIGNED ---
import 'package:flutter/material.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';

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
  static const double minHeight = 188;

  final StatusIndicator indicator;

  const CompactStatusIndicatorCard({super.key, required this.indicator});

  @override
  Widget build(BuildContext context) {
    final baseColor = indicator.iconColor ?? AppColors.primaryAccent;
    final gradient = [
      baseColor.withValues(alpha: 0.95),
      baseColor.withValues(alpha: 0.75),
    ];

    return Container(
      width: 160,
      constraints: const BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(indicator.icon, color: Colors.white, size: 24),
              ),
              if (indicator.hasAlert)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Внимание',
                        style: AppStyles.caption(context).copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            indicator.value,
            style: AppStyles.headline4(
              context,
            ).copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            indicator.label,
            style: AppStyles.caption(context).copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 0.3,
            ),
          ),
          if (indicator.subLabel.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              indicator.subLabel,
              style: AppStyles.caption(
                context,
              ).copyWith(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ],
      ),
    );
  }
}
