// lib/features/home/sheets/security_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/l10n/app_localizations.dart';
import 'package:ISS/features/home/sheets/glass_sheet_container.dart';

Widget buildSecuritySheet({
  required BuildContext context,
  required bool isArmed,
  required bool isLoading,
  required TextEditingController pinController,
  required List<TextInputFormatter> pinFormatters,
  required bool Function(String) isPinValid,
  required VoidCallback onArm,
  required void Function(String pin) onDisarm,
  required VoidCallback onOpenPinManagement,
}) {
  final loc = AppLocalizations.of(context);
  return glassSheetContainer(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        sheetHeader(context, isArmed ? loc.disarm : loc.arm),
        Text(
          isArmed
              ? 'Введите PIN для снятия с охраны'
              : 'Постановка на охрану не требует PIN.',
          style: AppStyles.bodyText2(context),
        ),
        const SizedBox(height: 24),
        if (isArmed)
          TextField(
            controller: pinController,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: pinFormatters,
            decoration: AppStyles.inputDecoration(
              context: context,
              hintText: 'PIN (4–8 цифр)',
            ),
          ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: AppStyles.primaryButtonStyle,
            onPressed:
                isLoading
                    ? null
                    : () {
                      if (isArmed) {
                        final pin = pinController.text.trim();
                        if (!isPinValid(pin)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Некорректный PIN (4–8 цифр)',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        onDisarm(pin);
                      } else {
                        Navigator.pop(context);
                        onArm();
                      }
                    },
            icon:
                isLoading
                    ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Icon(
                      isArmed
                          ? Icons.lock_open_rounded
                          : Icons.security_rounded,
                    ),
            label: Text(isArmed ? loc.disarm : loc.arm),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onOpenPinManagement();
          },
          child: const Text('Управление PIN-кодами'),
        ),
      ],
    ),
  );
}
