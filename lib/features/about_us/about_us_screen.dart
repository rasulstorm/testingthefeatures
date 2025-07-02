// lib/features/about_us/about_us_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ISS/appColor.dart'; // Убедитесь, что путь правильный
import 'package:ISS/features/main_menu_sheet.dart'; // Импортируем MainMenuSheet

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        // ДОБАВЛЕНА КНОПКА НАЗАД
        leading: const BackButton(
          color: AppColors.heading, // Явно указываем цвет для кнопки назад
        ),
        title: const Text(
          'О нас',
          style: TextStyle(color: AppColors.heading),
        ),
        backgroundColor: AppColors.secodnBg,
        iconTheme: const IconThemeData(color: AppColors.heading), // Цвет иконок в AppBar (включая BackButton по умолчанию)
        elevation: 0, // Убирает тень под AppBar

        // Сендвич (кнопка меню) в AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent, // Для кастомного фона в MainMenuSheet
                builder: (_) => const MainMenuSheet(),
              );
            },
            color: AppColors.heading, // Цвет иконки меню
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Text(
              'Добро пожаловать в ISS (Innovative Security Systems)!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.heading,
              ),
            ),
            const SizedBox(height: 20),

            // Информация о компании
            Card(
              color: AppColors.secodnBg,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Наша миссия',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Мы - компания Innovative Security Systems (ISS), лидер в разработке передовых решений для "Умного дома". Наша цель - сделать вашу жизнь безопаснее, комфортнее и эффективнее с помощью инновационных технологий.',
                      style: TextStyle(fontSize: 16, color: AppColors.text),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Что мы предлагаем?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Наше приложение "Умный дом" предоставляет полный контроль над всеми системами безопасности и автоматизации вашего дома. С ISS вы можете легко управлять освещением, климатом, видеонаблюдением, охранными системами и многими другими устройствами прямо со своего смартфона.',
                      style: TextStyle(fontSize: 16, color: AppColors.text),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Основные сервисы:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.heading,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _buildServiceItem(
                      context,
                      Icons.security,
                      'Комплексные системы безопасности: Мониторинг, датчики движения, уведомления в реальном времени.',
                    ),
                    _buildServiceItem(
                      context,
                      Icons.lightbulb_outline,
                      'Умное освещение: Настройка сценариев, удаленное управление, экономия энергии.',
                    ),
                    _buildServiceItem(
                      context,
                      Icons.thermostat,
                      'Климат-контроль: Автоматическая регулировка температуры для вашего комфорта.',
                    ),
                    _buildServiceItem(
                      context,
                      Icons.videocam,
                      'Видеонаблюдение: Доступ к камерам в любой точке мира, запись событий.',
                    ),
                    _buildServiceItem(
                      context,
                      Icons.smart_toy,
                      'Интеграция с умными устройствами: Поддержка широкого спектра сторонних гаджетов.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Контактная информация
            Card(
              color: AppColors.secodnBg,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Возникли вопросы?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Если у вас есть какие-либо вопросы, предложения или вы хотите узнать больше о наших услугах, пожалуйста, свяжитесь с нами.',
                      style: TextStyle(fontSize: 16, color: AppColors.text),
                    ),
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: () async {
                        final Uri emailLaunchUri = Uri(
                          scheme: 'mailto',
                          path: 'info@iss-control.kz',
                        );
                        if (await canLaunchUrl(emailLaunchUri)) {
                          await launchUrl(emailLaunchUri);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Не удалось открыть почтовое приложение'),
                              backgroundColor: AppColors.iconRed,
                            ),
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Icon(Icons.email, color: AppColors.primary, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            'info@iss-control.kz',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.iconGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 15, color: AppColors.text),
            ),
          ),
        ],
      ),
    );
  }
}