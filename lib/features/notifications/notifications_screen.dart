import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:intl/intl.dart';
// import 'package:ISS/features/main_menu_sheet.dart'; // УДАЛИТЬ: больше не нужен

final notificationsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final prefs = await SharedPreferences.getInstance();
  final refreshToken = prefs.getString('refreshToken');
  if (refreshToken == null) throw Exception('No refresh token');

  final refreshDio = Dio(BaseOptions(baseUrl: dio.options.baseUrl));
  final refreshResp = await refreshDio.post(
    '/account-management/refresh',
    data: {'refreshToken': refreshToken},
  );

  final data = refreshResp.data['data'];
  final newAccessToken = data['accessToken'];
  final newRefreshToken = data['refreshToken'];

  await prefs.setString('accessToken', newAccessToken);
  await prefs.setString('refreshToken', newRefreshToken);

  final response = await dio.get(
    '/user/notificationToken',
    options: Options(headers: {'Authorization': '$newAccessToken'}),
  );

  if (response.data is List) {
    return List<Map<String, dynamic>>.from(response.data);
  }
  return [];
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsyncValue = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      body: notificationsAsyncValue.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Text(
                'У вас пока нет уведомлений.',
                style: AppStyles.bodyText1(
                  context,
                ).copyWith(color: AppColors.getSecondaryTextColor(context)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final date =
                  notification['date'] != null
                      ? DateFormat(
                        'd MMMM y, HH:mm',
                        'ru_RU',
                      ).format(DateTime.parse(notification['date']))
                      : 'неизвестно';

              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: AppStyles.cardDecoration(context),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification['title'] ?? 'Без заголовка',
                        style: AppStyles.headline4(context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notification['body'] ?? 'Без описания',
                        style: AppStyles.bodyText1(context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Дата: $date',
                        style: AppStyles.bodyText2(context).copyWith(
                          color: AppColors.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading:
            () => Center(
              child: CircularProgressIndicator(color: AppColors.primaryAccent),
            ),
        error:
            (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Ошибка загрузки уведомлений: ${error.toString()}',
                      textAlign: TextAlign.center,
                      style: AppStyles.bodyText1(
                        context,
                      ).copyWith(color: AppColors.error),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(notificationsProvider),
                      style: AppStyles.primaryButtonStyle,
                      child: Text(
                        'Повторить',
                        style: AppStyles.bodyText1(
                          context,
                        ).copyWith(color: AppColors.textColorDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}
