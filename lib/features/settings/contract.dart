import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:ISS/core/network/dio_provider.dart';
import 'package:ISS/appColor.dart';
import 'package:ISS/appstyles.dart'; // Исправлен путь к appstyles.dart
import 'package:intl/intl.dart';
import 'package:ISS/l10n/app_localizations.dart'; // Импорт локализации

final contractsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
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
    '/user/contracts',
    options: Options(headers: {'Authorization': '$newAccessToken'}),
  );

  if (response.data is List) {
    return List<Map<String, dynamic>>.from(response.data);
  }
  return [];
});

class ContractsScreen extends ConsumerWidget {
  const ContractsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsyncValue = ref.watch(contractsProvider);
    final localizations = AppLocalizations.of(context); // Получаем объект локализации

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar( // ДОБАВЛЕН AppBar
        leading: BackButton( // Кнопка "Назад"
          color: AppColors.getTextColor(context),
        ),
        title: Text(
          localizations.myContractsTitle, // Локализованный заголовок
          style: AppStyles.headline3(context).copyWith(
            color: AppColors.getTextColor(context),
          ),
        ),
        backgroundColor: AppColors.getBackgroundColor(context),
        elevation: 0,
      ),
      body: contractsAsyncValue.when(
        data: (contracts) {
          if (contracts.isEmpty) {
            return Center(
              child: Text(
                localizations.noActiveContracts, // Локализованный текст
                style: AppStyles.bodyText1(context).copyWith(
                    color: AppColors.getSecondaryTextColor(context)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: contracts.length,
            itemBuilder: (context, index) {
              final contract = contracts[index];
              final dateNextPayment = contract['dateNextPayment'] != null
                  ? DateFormat('d MMMM y', localizations.localeName) // Используем localeName для форматирования
                      .format(DateTime.parse(contract['dateNextPayment']))
                  : localizations.unknown; // Используем локализованное "неизвестно"

              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: AppStyles.cardDecoration(context),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${localizations.contract}: ${contract['contractNumber'] ?? 'N/A'}', // Локализованный текст
                        style: AppStyles.headline4(context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${localizations.amountPaid}: ${contract['sum'] ?? 0} ₸', // Локализованный текст
                        style: AppStyles.bodyText1(context),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${localizations.nextPaymentDate}: $dateNextPayment', // Локализованный текст
                        style: AppStyles.bodyText2(context),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => Center(
            child: CircularProgressIndicator(color: AppColors.primaryAccent)),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(
                  '${localizations.errorLoadingContracts}: ${error.toString()}', // Локализованный текст
                  textAlign: TextAlign.center,
                  style: AppStyles.bodyText1(context)
                      .copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => ref.invalidate(contractsProvider),
                  style: AppStyles.primaryButtonStyle,
                  child: Text(localizations.retry, // Локализованный текст
                      style: AppStyles.bodyText1(context)
                          .copyWith(color: AppColors.textColorDark)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
