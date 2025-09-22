// lib/features/home/sheets/change_pin_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/features/home/sheets/glass_sheet_container.dart';

Widget buildChangePinSheet({
  required BuildContext context,
  required String title,
  required TextEditingController oldCtrl,
  required TextEditingController newCtrl,
  required List<TextInputFormatter> pinFormatters,
  required bool Function(String) isPinValid,
  required void Function(String oldPin, String newPin) onSave,
}) {
  return glassSheetContainer(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        sheetHeader(context, title),
        TextField(
          controller: oldCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: pinFormatters,
          decoration: AppStyles.inputDecoration(
            context: context,
            hintText: 'Старый PIN',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: newCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: pinFormatters,
          decoration: AppStyles.inputDecoration(
            context: context,
            hintText: 'Новый PIN (4–8 цифр)',
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: AppStyles.primaryButtonStyle,
            onPressed: () {
              final oldPin = oldCtrl.text.trim();
              final newPin = newCtrl.text.trim();
              if (!isPinValid(oldPin) || !isPinValid(newPin)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN должен быть 4–8 цифр')),
                );
                return;
              }
              Navigator.pop(context);
              onSave(oldPin, newPin);
            },
            child: const Text('Сохранить'),
          ),
        ),
      ],
    ),
  );
}
