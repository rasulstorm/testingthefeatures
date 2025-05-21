import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ISS/appColor.dart';

class MainMenuSheet extends StatelessWidget {
  const MainMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.secodnBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuItem(
            context,
            icon: Icons.security,
            label: 'Панель охраны',
            route: '/security-control',
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            icon: Icons.person,
            label: 'Профиль',
            route: '/settings',
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            icon: Icons.payment,
            label: 'Оплата',
            route: '/dashboard',
          ),
          const SizedBox(height: 12),
          _buildMenuItem(
            context,
            icon: Icons.notifications,
            label: 'Уведомления',
            route: '/notifications',
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        context.go(route);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.text),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
