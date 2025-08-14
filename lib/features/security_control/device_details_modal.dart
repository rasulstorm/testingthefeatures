import 'package:flutter/material.dart';
import 'package:ISS/appColor.dart'; // Ensure this path is correct
import 'package:ISS/appstyles.dart'; // Import AppStyles for consistent typography and decorations

class DeviceDetailsModal extends StatelessWidget {
  final dynamic device;

  const DeviceDetailsModal({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Apply the card background color from AppColors, which adapts to theme
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        // Keep the specific top border radius for modal consistency
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device Name - use a headline style for prominence
          Text(
            device['name'],
            style: AppStyles.headline3(context).copyWith(
              color: AppColors.getTextColor(context), // Ensure text color is consistent with theme
            ),
          ),
          const SizedBox(height: 16), // Increased spacing for better visual separation
          // Information rows, now styled using the helper method
          _info(context, 'Тип', device['type']?['description']),
          _info(context, 'Комната', device['room']?['name']),
          _info(context, 'Пространство', device['space']?['name']),
          _info(context, 'Webhook URL', device['hiteProWebhookURL']),
        ],
      ),
    );
  }

  /// Helper method to display a single information row with consistent styling.
  /// It uses RichText to allow different styles for the title and the value.
  Widget _info(BuildContext context, String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6), // Consistent vertical spacing for info lines
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$title: ',
              style: AppStyles.bodyText2(context).copyWith(
                color: AppColors.getSecondaryTextColor(context), // Secondary text color for the label
                fontWeight: FontWeight.w500, // Slightly bolder for the title part
              ),
            ),
            TextSpan(
              text: value ?? '-',
              style: AppStyles.bodyText1(context).copyWith(
                color: AppColors.getTextColor(context), // Primary text color for the value
                fontWeight: FontWeight.w600, // Bold for the actual value
              ),
            ),
          ],
        ),
      ),
    );
  }
}