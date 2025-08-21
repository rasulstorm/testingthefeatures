// lib/features/scenarios/scenarios_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Import go_router
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/l10n/app_localizations.dart'; // Если используете локализацию

class ScenariosScreen extends ConsumerWidget {
  const ScenariosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context); // Для локализации
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.scenariosTab,
          style: AppStyles.headline3(
            context,
          ).copyWith(color: AppColors.getTextColor(context)),
        ),
        backgroundColor: AppColors.getBackgroundColor(context),
        foregroundColor: AppColors.getTextColor(context),
        elevation: 0,
      ),
      backgroundColor: AppColors.getBackgroundColor(context),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.playlist_add_check,
              size: 80,
              color: AppColors.getSecondaryTextColor(context),
            ),
            const SizedBox(height: 20),
            Text(
              localizations.scenariosListEmpty, // Используем локализацию
              style: AppStyles.bodyText1(
                context,
              ).copyWith(color: AppColors.getSecondaryTextColor(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              localizations.createFirstScenarioPrompt, // Используем локализацию
              style: AppStyles.bodyText2(
                context,
              ).copyWith(color: AppColors.getLightGreyColor(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // ПЕРЕХОДИМ НА ЭКРАН СОЗДАНИЯ СЦЕНАРИЯ
                context.push('/create-scenario');
              },
              style: AppStyles.primaryButtonStyle,
              child: Text(
                localizations.createNewScenarioButton, // Используем локализацию
                style: AppStyles.bodyText1(
                  context,
                ).copyWith(color: AppColors.textColorDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
