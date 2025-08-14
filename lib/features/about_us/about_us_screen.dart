import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ISS/appcolor.dart';
import 'package:ISS/appstyles.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        leading: BackButton(color: AppColors.getTextColor(context)),
        title: Text('О нас', style: AppStyles.headline3(context)),
        backgroundColor: AppColors.getCardBackgroundColor(context),
        iconTheme: IconThemeData(color: AppColors.getTextColor(context)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Добро пожаловать в ISS (Innovative Security Systems)!',
              style: AppStyles.headline2(context),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: AppStyles.cardDecoration(context),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Наша миссия',
                      style: AppStyles.headline3(
                        context,
                      ).copyWith(color: AppColors.primaryAccent),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Мы - компания Innovative Security Systems (ISS), лидер в разработке передовых решений для "Умного дома". Наша цель - сделать вашу жизнь безопаснее, комфортнее и эффективнее с помощью инновационных технологий.',
                      style: AppStyles.bodyText1(context),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Что мы предлагаем?',
                      style: AppStyles.headline3(
                        context,
                      ).copyWith(color: AppColors.primaryAccent),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Наше приложение "Умный дом" предоставляет полный контроль над всеми системами безопасности и автоматизации вашего дома. С ISS вы можете легко управлять освещением, климатом, видеонаблюдением, охранными системами и многими другими устройствами прямо со своего смартфона.',
                      style: AppStyles.bodyText1(context),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Основные сервисы:',
                      style: AppStyles.headline4(context),
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
            Container(
              decoration: AppStyles.cardDecoration(context),
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Возникли вопросы?',
                      style: AppStyles.headline3(
                        context,
                      ).copyWith(color: AppColors.primaryAccent),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Если у вас есть какие-либо вопросы, предложения или вы хотите узнать больше о наших услугах, пожалуйста, свяжитесь с нами.',
                      style: AppStyles.bodyText1(context),
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
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Не удалось открыть почтовое приложение',
                                  style: AppStyles.bodyText2(
                                    context,
                                  ).copyWith(color: AppColors.textColorDark),
                                ),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.email,
                            color: AppColors.primaryAccent,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'info@iss-control.kz',
                            style: AppStyles.bodyText1(context).copyWith(
                              color: AppColors.primaryAccent,
                              decoration: TextDecoration.underline,
                              decorationColor: AppColors.primaryAccent,
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
          Icon(icon, color: AppColors.secondaryAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppStyles.bodyText2(context))),
        ],
      ),
    );
  }
}
