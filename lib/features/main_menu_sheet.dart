// lib/features/main_menu_sheet.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart'; // Import AppStyles for consistent design
import 'package:ISS/features/about_us/about_us_screen.dart'; // Импортируем новую страницу "О нас"

class MainMenuSheet extends StatelessWidget {
  const MainMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // Применяем фоновый цвет карточки из AppColors, который адаптируется к теме
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ручка для закрытия меню
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: AppColors.getLightGreyColor(context), // Используем цвет из AppColors для ручки
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12), // Отступ после ручки

          _buildMenuItem(
            context,
            icon: Icons.security,
            label: 'Панель охраны',
            targetRoute: '/security-control', // Используем targetRoute для go()
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            icon: Icons.person,
            label: 'Профиль',
            targetRoute: '/settings', // Используем targetRoute для go()
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            icon: Icons.payment,
            label: 'Оплата',
            targetRoute: '/dashboard', // Используем targetRoute для go()
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            icon: Icons.notifications,
            label: 'Уведомления',
            targetRoute: '/notifications', // Используем targetRoute для go()
          ),
          const SizedBox(height: 12),

          // ИЗМЕНЕННЫЙ ПУНКТ МЕНЮ: О нас
          _buildMenuItem(
            context,
            icon: Icons.info_outline, // Иконка для "О нас"
            label: 'О нас',
            targetRoute: '/about-us', // Новый маршрут
            usePush: true, // Указываем, что для этого пункта нужно использовать push()
          ),
          const SizedBox(height: 12), // Отступ после нового пункта
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String targetRoute, // Изменил имя параметра для ясности
    bool usePush = false, // Новый параметр для управления push/go
    // Устанавливаем цвета по умолчанию из AppColors и AppStyles
    Color iconColor = AppColors.primaryAccent,
    Color labelColor = AppColors.textColorDark,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop(); // Закрыть bottom sheet
        if (usePush) {
          context.push(targetRoute); // ИСПОЛЬЗУЕМ PUSH ДЛЯ "О НАС"
        } else {
          context.go(targetRoute); // Для остальных пунктов используем go
        }
      },
      borderRadius: AppStyles.borderRadiusAll(12), // Применяем радиус из AppStyles
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        // Применяем декорацию карточки из AppStyles
        decoration: AppStyles.cardDecoration(context).copyWith(
          borderRadius: AppStyles.borderRadiusAll(12), // Единый радиус для элементов меню
          boxShadow: [], // Убираем тень, если не нужна для элементов меню, или настраиваем
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor), // Используем iconColor
            const SizedBox(width: 16),
            Text(
              label,
              style: AppStyles.bodyText1(context).copyWith(color: labelColor), // Используем bodyText1 и labelColor
            ),
          ],
        ),
      ),
    );
  }
}