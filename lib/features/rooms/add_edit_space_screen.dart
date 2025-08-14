// lib/features/rooms/add_edit_space_screen.dart
// Раз у бэка НЕТ эндпоинта создания Space, этот экран только информирует пользователя.
// Можешь удалить этот файл и роут на него, если он не нужен.

import 'package:flutter/material.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';

class AddEditSpaceScreen extends StatelessWidget {
  const AddEditSpaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Space'),
        backgroundColor: AppColors.getBackgroundColor(context),
        foregroundColor: AppColors.getTextColor(context),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Создание Space выполняется на сервере. '
            'Клиент получает Space и Rooms через getObjects. '
            'Этот экран можно удалить.',
            style: AppStyles.bodyText1(context),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
