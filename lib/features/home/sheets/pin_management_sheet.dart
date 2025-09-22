// lib/features/home/sheets/pin_management_sheet.dart
import 'package:flutter/material.dart';
import 'package:ISS/features/home/sheets/glass_sheet_container.dart';
import 'package:ISS/features/home/widgets/pin_action_tile.dart';

Widget buildPinManagementSheet({
  required BuildContext context,
  required VoidCallback onSetPins,
  required VoidCallback onChangeDisarm,
  required VoidCallback onChangeDuress,
}) {
  return glassSheetContainer(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        sheetHeader(context, 'PIN-коды охраны'),
        const SizedBox(height: 12),
        PinActionTile(
          icon: Icons.key_rounded,
          title: 'Назначить PIN-коды',
          subtitle: 'Основной и тревожный',
          onTap: onSetPins,
        ),
        const SizedBox(height: 12),
        PinActionTile(
          icon: Icons.lock_reset_rounded,
          title: 'Сменить основной PIN',
          subtitle: 'Изменить disarm PIN',
          onTap: onChangeDisarm,
        ),
        const SizedBox(height: 12),
        PinActionTile(
          icon: Icons.warning_amber_rounded,
          title: 'Сменить тревожный PIN',
          subtitle: 'Изменить duress PIN',
          onTap: onChangeDuress,
        ),
      ],
    ),
  );
}
