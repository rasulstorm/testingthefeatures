// lib/widgets/quick_action_button.dart
// --- CORRECTED ---

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';

class QuickActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const QuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: AppStyles.glassmorphicBoxDecoration(
            context,
          ).copyWith(borderRadius: BorderRadius.circular(20.0)),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20.0),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20.0,
                  horizontal: 16.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: AppColors.getTextColor(context),
                    ),
                    const SizedBox(width: 12),
                    // --- FIX IS HERE ---
                    Flexible(
                      child: Text(
                        label,
                        style: AppStyles.bodyText1(
                          context,
                        ).copyWith(fontWeight: FontWeight.w600),
                        // Add these properties to prevent wrapping and show "..." if text is too long
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // --- END OF FIX ---
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
