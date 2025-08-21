// lib/widgets/server_unavailable_widget.dart

import 'package:flutter/material.dart';
import 'package:ISS/appcolor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/l10n/app_localizations.dart';

class ServerUnavailableWidget extends StatelessWidget {
  final VoidCallback onRefresh;

  const ServerUnavailableWidget({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.construction_rounded, // Иконка "стройки"
              size: 80,
              color: AppColors.primaryAccent.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              localizations
                  .serverUnavailableTitle, // TODO: "Сервер временно недоступен"
              textAlign: TextAlign.center,
              style: AppStyles.headline3(context),
            ),
            const SizedBox(height: 12),
            Text(
              localizations
                  .serverUnavailableMessage, // TODO: "Мы уже знаем о проблеме и работаем над ее решением. Пожалуйста, попробуйте обновить страницу."
              textAlign: TextAlign.center,
              style: AppStyles.bodyText1(
                context,
              ).copyWith(color: AppColors.getSecondaryTextColor(context)),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(localizations.refresh), // TODO: "Обновить"
              onPressed: onRefresh,
              style: AppStyles.primaryButtonStyle,
            ),
          ],
        ),
      ),
    );
  }
}
