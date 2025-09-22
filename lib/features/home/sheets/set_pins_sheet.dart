// lib/features/home/sheets/set_pins_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/features/home/sheets/glass_sheet_container.dart';

Widget buildSetPinsSheet({
  required BuildContext context,
  required TextEditingController disarmCtrl,
  required TextEditingController duressCtrl,
  required List<TextInputFormatter> pinFormatters,
  required bool Function(String) isPinValid,
  required void Function(String disarm, String duress) onSave,
}) {
  return glassSheetContainer(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        sheetHeader(context, 'Назначить PIN-коды'),
        TextField(
          controller: disarmCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: pinFormatters,
          decoration: AppStyles.inputDecoration(
            context: context,
            hintText: 'Основной PIN (disarm)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: duressCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          inputFormatters: pinFormatters,
          decoration: AppStyles.inputDecoration(
            context: context,
            hintText: 'Тревожный PIN (duress)',
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: AppStyles.primaryButtonStyle,
            onPressed: () {
              final disarm = disarmCtrl.text.trim();
              final duress = duressCtrl.text.trim();
              if (!isPinValid(disarm) || !isPinValid(duress)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN должен быть 4–8 цифр')),
                );
                return;
              }
              Navigator.pop(context);
              onSave(disarm, duress);
            },
            child: const Text('Сохранить'),
          ),
        ),
      ],
    ),
  );
}
