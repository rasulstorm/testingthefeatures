// lib/utils/permission_manager.dart

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ISS/appcolor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/l10n/app_localizations.dart';

class PermissionManager {
  // Универсальный метод для запроса геолокации
  static Future<bool> requestLocationPermission(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    // 1. Сначала проверяем текущий статус
    var status = await Permission.locationWhenInUse.status;

    // 2. Если уже разрешено, просто возвращаем true
    if (status.isGranted) {
      return true;
    }

    // 3. Если отклонено навсегда, показываем наш кастомный диалог
    if (status.isPermanentlyDenied) {
      await _showPermissionDialog(
        context,
        title:
            localizations
                .locationPermissionNeededForWifi, // TODO: "Доступ к геолокации запрещен"
        content:
            localizations
                .locationPermissionNeededForWifi, // TODO: "Чтобы определять Wi-Fi, разрешите доступ к геолокации в настройках приложения."
      );
      return false;
    }

    // 4. Если еще не спрашивали или было отказано временно, показываем системный запрос
    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
      return status.isGranted;
    }

    // Во всех остальных случаях (например, .restricted) считаем, что доступа нет
    return false;
  }

  // Приватный виджет для нашего кастомного диалога
  static Future<void> _showPermissionDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    final localizations = AppLocalizations.of(context)!;
    return showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: AppColors.getCardBackgroundColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: AppStyles.borderRadiusAll(16),
            ),
            title: Text(title, style: AppStyles.headline4(context)),
            content: Text(content, style: AppStyles.bodyText1(context)),
            actions: [
              TextButton(
                child: Text(
                  localizations.cancel,
                  style: TextStyle(
                    color: AppColors.getSecondaryTextColor(context),
                  ),
                ),
                onPressed: () => Navigator.pop(dialogContext),
              ),
              ElevatedButton(
                child: Text(
                  localizations.generalSettings,
                ), // TODO: "В настройки"
                style: AppStyles.primaryButtonStyle,
                onPressed: () {
                  openAppSettings(); // Открывает системные настройки этого приложения
                  Navigator.pop(dialogContext);
                },
              ),
            ],
          ),
    );
  }
}
